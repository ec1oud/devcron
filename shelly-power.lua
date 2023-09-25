#!/usr/bin/lua
--
-- check power consumed through a Shelly Plug
--
-- configuration
shellyIP = "10.your.shelly.address.here"

-- variables

-- imports
http = require("socket.http")
--~ json = require("luci.jsonc")

-- helpers
--~ print = function(...) io.write(table.concat({...}, "\t")) io.write("\n") end

local url = string.format("http://%s/meter/0", shellyIP)
print(url)

-- it will be a GET request: no second parameter
-- http://w3.impa.br/~diego/software/luasocket/http.html#request
local body, headers, code = http.request(url)
if headers == 200 then
	local timeStr = os.date("%F %H:%M")
	print(timeStr, body)
--~ 	local ok, data = pcall(json.parse, body)
--~ 	if (ok and type(data) == "table") then
--~ 		print("power:", data.power)
--~ 	end
end
