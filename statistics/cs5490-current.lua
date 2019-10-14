#!/usr/bin/lua
local socket = require "socket"
local string = require "string"
local port_name = "/dev/ttyS1"
local out = io.stdout
chip = require "cs5490"

local err = chip.open(port_name)
if err ~= "" then
	out:write(string.format("can't open serial port '%s', error: '%s'\n", port_name, err))
	return
end

require "cs5490-calibration"
socket.sleep(0.5)

chip.sendInstruction(0x15) -- continuous conversion
socket.sleep(0.9)
out:write(string.format('PUTVAL "pool/exec-pool/current-pump" interval=30 N:%f\n', currentScale * chip.readRegisterFixed0dot24(16, 6)))
