devcron is a simple home automation system intended to run on an OpenWRT-based router or
some other suitably small system.

It makes use of mountable "device filesystems" like [x10dev](http://wish.sourceforge.net/index2.html)
and [OWFS](http://owfs.org/): it assumes that turning something on is as simple as

    echo 1 > /mnt/devices/foo

Timers are managed via individual config files (oversimplified at this point; maybe they
should be .ini files, but they aren't) which can then be edited via the web interface.
A web interface in PHP is included, but it would be better to rewrite it in Lua for OpenWRT.

To build devcrond on OpenWRT, you either need enough space to install gcc on the router,
in which case you need [an overlay FS on a USB stick](https://wiki.openwrt.org/doc/howto/extroot);
or else [build OpenWRT from scratch](https://wiki.openwrt.org/doc/devel/crosscompile) in
order to get a toolchain for cross-compiling.  The latter is giving me trouble due to
[issue 372](https://github.com/openwrt/openwrt/issues/372) so I went with the former.

