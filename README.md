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
is a nice board for this purpose: it has 32MB of memory (so, enough to handle
some light scripting), two relays which can be directly controlled via Linux
GPIO, USB (perhaps for an interface to a one-wire network, X10 or some such),
dual ethernet, WiFi, and a low price.  It could be used directly as a
thermostat, pool pump controller or the like, as well as the central node of a
home automation or security system.

