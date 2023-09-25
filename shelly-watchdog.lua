#!/usr/bin/lua
--
-- intended to run as a periodic cron job:
-- check that a particular machine is consuming a believable amount of power through a Shelly Plug and
-- can be pinged; if not, "kerchunk" the power (off and back on again).
--
-- configuration
shellyIP = "10.your.shelly.address.here"
expectedMinPower = 5
targetSystemUrl = "http://10.your.target.IP.here"

-- variables

-- imports
socket = require("socket")
http = require("socket.http")
json = require("luci.jsonc")

-- helpers
print = function(...) io.write(table.concat({...}, "\t")) io.write("\n") end

local function checkOk()
	local shellyQueryUrlFmt = "http://%s/meter/0"
--~ 	print(os.date("%F %H:%M"), os.time(), "setRelay", (relayState and "on" or "off"), "->", stateStr)
--~ 	local timestampNS = socket.gettime()*1000000000

	local url = string.format(shellyQueryUrlFmt, shellyIP)
	print(url)

	-- it will be a GET request: no second parameter
	-- http://w3.impa.br/~diego/software/luasocket/http.html#request
	local body, headers, code = http.request(url)
	if headers == 200 then
		print(body)
		local ok, data = pcall(json.parse, body)
		if (ok and type(data) == "table") then
			local powerOk = (data.power >= expectedMinPower)
			print("power:", data.power, powerOk and "ok" or "too low")
			if (not powerOk) then
				return string.format("power: %f < expected %s", data.power, expectedMinPower)
			end
		end
	end

--~ 	local body, headers, code = http.request(targetSystemUrl)
--~ 	if (body) then
--~ 		print(body)
--~ 	else
--~ 		return string.format("failed: %s", headers)
--~ 	end

	return false -- no error
end

local function setRelay(state)
	local shellySetRelayUrlFmt = "http://%s/relay/0?turn=%s"
	local stateStr = state and "on" or "off"
	local url = string.format(shellySetRelayUrlFmt, shellyIP, stateStr)
--~ 	print(url)

	local body, headers, code = http.request(url)
--~ 	if headers == 200 then
--~ 		print("shelly: success", body)
--~ 	else
--~ 		print("shelly:", headers)
--~ 	end
end

-- main
err = checkOk()
if (err) then
	local timeStr = os.date("%F %H:%M")
	local logfile = io.open("/var/log/watchdog.log", "a")
	io.output(logfile)
	print(timeStr, err)
	setRelay(false)
	socket.sleep(30)
	setRelay(true)
end
