#!/bin/sh
#
# $Header$
#
#--------------------------------------------------------------------------------------#
# TODO
#
#--------------------------------------------------------------------------------------#

/root/files/data/developent/compile_drivers/make-relevant-rc.local-and-interface-defs.sh
case $? in 
	0)	:
	;;
	*)	# compile new versions of drivers if required
		/root/files/data/developent/compile_drivers/compile-and-install-igb-and-ixgbe-drivers.sh igb 
		/root/files/data/developent/compile_drivers/compile-and-install-igb-and-ixgbe-drivers.sh ixgbe
	;;
esac
