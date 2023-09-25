devcron is a simple home automation system intended to run on an OpenWRT-based
router or some other suitably small system.

It makes use of mountable "device filesystems" like 
[x10dev](http://wish.sourceforge.net/index2.html)
and [OWFS](http://owfs.org/) and [GPIO](https://elinux.org/GPIO): 
it assumes that turning something on is as simple as

    echo 1 > /mnt/devices/foo

In the old-C-version git branch, timers were managed via individual config
files which could be edited via the web interface.  ATM this isn't ready for
OpenWRT usage.  The advantage of rewriting everything in Lua (ongoing and
incomplete) is that Lua is already there as part of OpenWRT, whereas a C
compiler is not, and in fact gcc takes up more space in flash memory than most
routers have available.  (Why does OpenWRT not include a small compiler, like tcc?)

An Olimex [RT5350F EVB](https://www.olimex.com/Products/OLinuXino/RT5350F/RT5350F-OLinuXino-EVB/)
is a nice board for this purpose: it has 32MB of memory (so, more than enough
to handle some light scripting), two relays which can be directly controlled
via Linux GPIO, USB (perhaps for an interface to a one-wire network, X10 or
some such), dual ethernet, WiFi, and a low price.  It could be used directly as
a thermostat, pool pump controller or the like, as well as the central node of
a home automation or security system, and even act as a WiFi range extender
at the same time.

devcron.lua is a daemon meant to run indefinitely.  But keeping processes
running indefinitely is another problem... so perhaps it's better to use
cron which is already reliable enough to stay running indefinitely.

periodic.lua is a script meant to run from a cron job, perhaps every minute
or every 5 minutes or something like that.  Currently it calculates sunrise
and sunset times, calculates a suitable amount of time for the pool pump to run,
decides whether at this time the pump should be running or not, checks the
state of the relay, changes state if necessary, and when state changes,
logs it to an influxdb instance.

shelly-power.lua just reads the power usage from a
[Shelly Plug](https://kb.shelly.cloud/knowledge-base/shelly-plug-s)
(or another in that family of devices), and shelly-watchdog.lua
uses a Shelly for a watchdog: verify that a machine is running
(and optionally verify that its web server is ok) else cycle its power
(assuming you have configured its BIOS setting to automatically
power on when power is restored after loss).

# Dependencies
OpenWrt:
```opkg install collectd-mod-exec kmod-fs-vfat kmod-usb-storage luabitop luasec lua-rs232 luasocket shadow-su```
- module for collectd to execute arbitrary statistic-providing scripts
- USB mass storage to be able to write to a USB flash drive instead of internal flash
- FAT filesystem because your flash drive is probably formatted that way
- lua bit operations to do the math to convert register values to real numbers
- luasec to provide https capability to talk to influxdb
- lua-rs232 to talk to the CS5490 (must be patched to support 600 baud)
- luasocket for sleep(), gettime() and http
- su command for testing scripts as the "nobody" user

# Installation
- Get the USB drive mounted, for RRDtool databases: https://openwrt.org/docs/guide-user/storage/usb-drives-quickstart
- set up the cron jobs as root: ```crontab -e``` and paste in the jobs from the crontab file here
