#!/usr/bin/lua
local socket = require "socket"
local https = require "ssl.https"
local string = require "string"
local port_name = "/dev/ttyS1"
local out = io.stdout
chip = require "cs5490"

local influxServerAddr = ""
local influxServerPort = 8086
local influxUser = ""
local influxPass = ""

local serverUrl = string.format("https://%s:%d/write?db=homeauto&rp=energy_rp&u=%s&p=%s",
		influxServerAddr, influxServerPort, influxUser, influxPass)

local err = chip.open(port_name)
if err ~= "" then
	out:write(string.format("can't open serial port '%s', error: '%s'\n", port_name, err))
	return
end

require "cs5490-calibration"
socket.sleep(0.5)

chip.sendInstruction(0x15) -- continuous conversion
socket.sleep(0.9)
local timestampNS = socket.gettime()*1000000000
local current = currentScale * chip.readRegisterFixed0dot24(16, 6)
local query = string.format("energy,location=earll2314,device=poolpump current=%f", current)
local body, code, headers, status = https.request(serverUrl, query)
out:write(string.format('PUTVAL "pool/exec-pool/current-pump" interval=30 N:%f\n', current))
