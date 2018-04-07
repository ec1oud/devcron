#!/usr/bin/lua
-- configuration
locationInfo = {lat=33.4827, lon=-112.0321, offset=-7} -- Phoenix
--~ locationInfo = {lat=59.9126, lon=10.7399, offset=2} -- Oslo
poolPumpOnTime = 20 -- hours and fractions: e.g. 20.5 would mean 8:30 PM

-- variables
hoursToSeconds = 3600
dayOfYear = -1
sunrise = 0
sunriseHour = 0
sunset = 0
sunsetHour = 0
buttonState = false
relayState = false
relayOverridden = false
poolPumpOffTime = 6
poolPumpOnTimeToday = 0
poolPumpOffTimeToday = 0

-- helpers
local function readGpioState(name)
	local f = assert(io.open("/sys/class/gpio/" .. name .. "/value", "r"))
	local s = tonumber(f:read("*all")) == 1
	f:close()
	return s
end

local function setRelay(state)
	if (relayState ~= state) then
		print(os.date("%x %H:%M"), os.time(), "setRelay", state, (relayOverridden and "overridden") or "")
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
	local runTime = minMax(6, 12, (sunsetHour - sunriseHour - 8) * 1.5)
	local ret = startTime + runTime
	-- But if we go past midnight, convert to time of the next day.
--~ 	if (ret >= 24) then
--~ 		ret = ret - 24
--~ 	end
	print("pool pump starting", startTime, "running", runTime, "ending", ret)
	return ret
end

local function sameMinute(hours1, hours2)
	return math.abs(hours1 - hours2) < 0.017
end

-- main
lustrous = require "lustrous"
--~ relayState = readGpioState("relay1")

while true do
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
		print("today began at", startOfTodayTime, "now is", nowTime)
		sunrise, sunset, lengthHours, lengthMinutes = lustrous.get(locationInfo)
		sunriseHour = timestampToHour(sunrise)
		sunsetHour = timestampToHour(sunset)
		print("as of", os.date("%x %H:%M", nowTime), nowHour,
			"sunrise", os.date("%x %H:%M", sunrise), sunriseHour, "sunset", os.date("%x %H:%M", sunset), sunsetHour,
			"length of day", lengthHours .. ":" .. lengthMinutes, "relay", relayState)
		poolPumpOffTime = poolOffTimeCalculator(poolPumpOnTime)
		poolPumpOnTimeToday = startOfTodayTime + poolPumpOnTime * hoursToSeconds
		poolPumpOffTimeToday = startOfTodayTime + poolPumpOffTime * hoursToSeconds

--~ 		if (poolPumpOffTimeToday < poolPumpOnTimeToday) then
--~ 			poolPumpOffTimeToday = poolPumpOffTimeToday + hoursToSeconds  * 24
--~ 		end
		relayOverridden = false
		print("pool pump should turn on at", poolPumpOnTime, poolPumpOnTimeToday, "from now", (poolPumpOnTimeToday - nowTime),
			"off at", poolPumpOffTime, poolPumpOffTimeToday, "from now", (poolPumpOffTimeToday - nowTime), "runtime", poolPumpOffTimeToday - poolPumpOnTimeToday)
	end
	if (not relayOverridden) then
		setRelay(nowTime > poolPumpOnTimeToday and nowTime < poolPumpOffTimeToday)
	end
	local buttonStateNow = readGpioState("button")
	if (buttonState ~= buttonStateNow) then
--~ 		print("button", buttonStateNow)
		buttonState = buttonStateNow
		if (buttonStateNow) then
			relayOverridden = true
			setRelay(not relayState)
		end
	end
	os.execute("sleep 1")
end
