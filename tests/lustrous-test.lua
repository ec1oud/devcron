lustrous = require "lustrous"
for k,v in pairs(lustrous) do print(k, v) end
--~ lustrous.init()
--~ print ("get_time", lustrous.get_time(lat=59.9234, lon=10.5591))
--~ local rise, set, lengthHours, lengthMinutes = lustrous.get{lat=59.9126, lon=10.7399, offset=2} -- Oslo
local rise, set, lengthHours, lengthMinutes = lustrous.get{lat=33.48345, lon=-112.03158, offset=-7} -- Phoenix
print("now", os.time(), "sunrise and sunset, length in hours and min", rise, set, lengthHours, lengthMinutes)
print("formatted", os.date("%x %H:%M"), os.date("%x %H:%M", rise), os.date("%x %H:%M", set))
local rise, set, lengthHours, lengthMinutes = lustrous.get{lat=33.48345, lon=-112.03158, offset=-7, date=os.date("*t", 1513858392)} 
print("winter Phoenix", os.date("%x %H:%M", 1513858392), os.date("%x %H:%M", rise), os.date("%x %H:%M", set), lengthHours, lengthMinutes)
local rise, set, lengthHours, lengthMinutes = lustrous.get{lat=33.48345, lon=-112.03158, offset=-7, date=os.date("*t", 1529583192)} 
print("summer Phoenix", os.date("%x %H:%M", 1529583192), os.date("%x %H:%M", rise), os.date("%x %H:%M", set), lengthHours, lengthMinutes)
local rise, set, lengthHours, lengthMinutes = lustrous.get{lat=59.9126, lon=10.7399, offset=1, date=os.date("*t", 1513858392)} 
print("winter Oslo", os.date("%x %H:%M", 1513858392), os.date("%x %H:%M", rise), os.date("%x %H:%M", set), lengthHours, lengthMinutes)
local rise, set, lengthHours, lengthMinutes = lustrous.get{lat=59.9126, lon=10.7399, offset=1, date=os.date("*t", 1529583192)} 
print("summer Oslo", os.date("%x %H:%M", 1529583192), os.date("%x %H:%M", rise), os.date("%x %H:%M", set), lengthHours, lengthMinutes)
