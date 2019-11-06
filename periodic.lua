#!/usr/bin/lua
--
-- devcron.lua is a daemon.  This is an alternative implementation intended to
-- run as a periodic cron job; it makes state changes as necessary, then exits.
--
-- configuration
locationInfo = {lat=33.4827, lon=-112.0321, offset=-7} -- Phoenix
--~ locationInfo = {lat=59.9126, lon=10.7399, offset=2} -- Oslo
poolPumpOnTime = 20 -- hours and fractions: e.g. 20.5 would mean 8:30 PM
influxServerUrl = "http://<ip-addr>:<port>/write?db=homeauto"

-- variables
hoursToSeconds = 3600
dayOfYear = -1
sunrise = 0
sunriseHour = 0
sunset = 0
sunsetHour = 0
buttonState = false
relayState = false
poolRunTime = 0
poolPumpOffTime = 6
startOfTodayTime = 0
startOfYesterdayTime = 0
poolPumpOnTimeToday = 0
poolPumpOffTimeToday = 0
poolPumpOnTimeYesterday = 0
poolPumpOffTimeYesterday = 0

-- helpers
print = function(...) io.write(table.concat({...}, "\t")) io.write("\n") end

local function readUptime() -- in days
	local f = assert(io.open("/proc/uptime", "r"))
	local s = tonumber(f:read("*n")) / hoursToSeconds / 24
	f:close()
	return s
end

local function logInfluxRelayState(state)
	local socket = require("socket")
	local http = require("socket.http")
	local timestampNS = socket.gettime()*1000000000
	local query = string.format("state,location=earll2314,device=poolpump,uptime=%s,sunrise=%s,sunset=%s,runtime=%s running=%s ",
			tostring(readUptime()), tostring(sunriseHour), tostring(sunsetHour), tostring(poolRunTime), tostring(state) )
--~ 	print(query)

	-- it will be a POST request because the "body" is given as the second parameter
	-- http://w3.impa.br/~diego/software/luasocket/http.html#request
	local body, headers, code = http.request(influxServerUrl, query)
	if body == nil then
		print("influx logging:", headers)
	elseif headers == 204 then
		print("influx logging: success")
	else
		print("influx logging:", headers)
	end
end

local function readGpioState(name)
	local f = assert(io.open("/sys/class/gpio/" .. name .. "/value", "r"))
	local s = tonumber(f:read("*all")) == 1
	f:close()
	return s
end

local function setRelay(state)
	if (relayState ~= state) then
		print(os.date("%F %H:%M"), os.time(), "setRelay", (relayState and "on" or "off"))
		logInfluxRelayState(state)
	end
	local relayf = assert(io.open("/sys/class/gpio/relay1/value", "w"))
	local stateString = (state and "1") or "0"
	relayf:write(stateString)
	relayf:close()
	relayState = state
end

local function minMax(min, max, input)
	local ret = (input > min and input) or min
	ret = (ret < max and ret) or max
	return ret
end

local function timestampToHour(t)
	return tonumber(os.date("%H", t)) + tonumber(os.date("%M", t)) / 60
end

--~ Calculate a "good" end time for the pool pump, based
--~ on the given start time and the sunrise/sunset times, such that
--~ it will run for a long time on long summer days and a short time
--~ on winter days, but never less than 6 hours or longer than 12 hours.
local function poolOffTimeCalculator(startTime)
	poolRunTime = minMax(6, 12, (sunsetHour - sunriseHour - 8) * 1.5)
	local ret = startTime + poolRunTime
	print("pool pump starting", startTime, "running", poolRunTime, "ending", ret)
	return ret
end

local function sameMinute(hours1, hours2)
	return math.abs(hours1 - hours2) < 0.017
end

-- convert from a string like 20:04 to fractional hours like 20.066667
function convert_time(s)
	local colon_from, colon_to = string.find(s, ':', 1)
	return tonumber(string.sub(s, 0, colon_from - 1)) + tonumber(string.sub(s, colon_to+1)) / 60.0;
end

-- main
local logfile = io.open("/var/log/periodic.log", "a")
io.output(logfile)
lustrous = require "lustrous"
relayState = readGpioState("relay1")

local fs = require "nixio.fs"
local json = require "luci.jsonc"

local ok, timerdata = pcall(json.parse, fs.readfile("/root/prj/devcron/config/timer.json"))
if (ok and type(timerdata) == "table") then
	poolPumpOnTime = convert_time(timerdata.start_time)
end

local nowTime = os.time()
local now = os.date("*t", nowTime)
local nowHour = timestampToHour(nowTime)
local doy = lustrous.day_of_year(now)
if (doy ~= dayOfYear) then
	dayOfYear = doy
	local startOfToday = os.date("*t", nowTime)
	startOfToday.hour = 0
	startOfToday.min = 0
	startOfToday.sec = 0
	startOfTodayTime = os.time(startOfToday)
	startOfYesterdayTime = startOfTodayTime - (hoursToSeconds * 24)
	print("yesterday began at", startOfYesterdayTime, "today began at", startOfTodayTime, "now is", nowTime)
	sunrise, sunset, lengthHours, lengthMinutes = lustrous.get(locationInfo)
	sunriseHour = timestampToHour(sunrise)
	sunsetHour = timestampToHour(sunset)
	lengthHours = - lengthHours
	print("as of", os.date("%F %H:%M", nowTime), nowHour,
	    "uptime", readUptime(),
		"sunrise", os.date("%F %H:%M", sunrise), sunriseHour, "sunset", os.date("%F %H:%M", sunset), sunsetHour,
		"length of day", lengthHours .. ":" .. lengthMinutes, "relay", (relayState and "on" or "off"))
	poolPumpOffTime = poolOffTimeCalculator(poolPumpOnTime)
	poolPumpOnTimeToday = startOfTodayTime + poolPumpOnTime * hoursToSeconds
	poolPumpOffTimeToday = startOfTodayTime + poolPumpOffTime * hoursToSeconds
	poolPumpOnTimeYesterday = startOfYesterdayTime + poolPumpOnTime * hoursToSeconds
	poolPumpOffTimeYesterday = startOfYesterdayTime + poolPumpOffTime * hoursToSeconds
	print("pool pump on at", poolPumpOnTimeYesterday, poolPumpOnTimeToday, "from now", (poolPumpOnTimeToday - nowTime),
		"off at", poolPumpOffTimeYesterday, poolPumpOffTimeToday, "from now", (poolPumpOffTimeToday - nowTime), "runtime", poolPumpOffTimeToday - poolPumpOnTimeToday)
end
setRelay((nowTime > poolPumpOnTimeYesterday and nowTime < poolPumpOffTimeYesterday) or (nowTime > poolPumpOnTimeToday and nowTime < poolPumpOffTimeToday))
