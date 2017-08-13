#!/bin/sh
#
# $Header$
#
#--------------------------------------------------------------------------------------#
# Compiling igb drivers for FastNetMon and make IP config files. Save in
#	/opt/netmap-`kernel version`-`compile-time`/`driver`/ e.g:
# e.g.
#	/opt/netmap/4.4.0-87-generic/igb
#	/opt/netmap/4.4.0-87-generic/ixgbe
#
# It sould be used together with /erc/rc.local and 
# /etc/network/interfaces.d/`interface name used by fastnetmon`
#
# The valid interface config file and rc.local will be written here:
# /root/files/data/developent/`driver name`
#
# The build dir(s) will be stored in /opt/netmap-`kernel version`-`compile-time` e.g:
# /opt/netmap-4.4.0-87-generic-2017-08-08-igb/netmap.build.dir
# /opt/netmap-4.4.0-87-generic-2017-08-08-ixgbe/netmap.build.dir
#--------------------------------------------------------------------------------------#
set -e

# Kernel vesion - driver must match the running kernel !
UNAME_R=`uname -r`

# Drivers
DRIVER=ixgbe
DRIVER=igb

case $1 in 
	ixgbe)	DRIVER="ixgbe"
	;;
	igb)	DRIVER="igb"
	;;
	*)	echo "usage: $0 igb | ixgbe"; exit
	;;
esac

# Install here
DRIVERPATH=/opt/netmap/${UNAME_R}/${DRIVER}/LINUX

# Full path to drivers
NETMAP_KO=${DRIVERPATH}/netmap.ko
IGB_KO=${DRIVERPATH}/${DRIVER}/${DRIVER}.ko

# Stop if drivers are installed allready
if [ -e ${NETMAP_KO} -a -e ${IGB_KO} ]; then
	echo "found ${NETMAP_KO}"
	echo "found ${IGB_KO}"
else
	# we have to install the drivers, either bechause we are the compile host or the kernel
	# has been upgraded (apt-get -y dist-upgrade ... )

	wget -N https://gist.githubusercontent.com/pavel-odintsov/6353bfd3bfd7dba2d99a/raw/f8b0e15ef203b343d846e17be9dfec25db1172e3/netmap_install.pl
	/bin/mv netmap_install.pl netmap_install.pl.ORG

	NOW=`date '+%Y-%m-%d'`
	NETMAPDIR=/opt/netmap-${UNAME_R}-${NOW}-${DRIVER}/

	mkdir -p $NETMAPDIR

	# Replacing drivername in perl script
	case ${DRIVER} in
		"ixgbe")
				echo "changing $selected_driver to ixgbe in netmap_install.pl ... "
				sed 's/my $selected_driver.*/my $selected_driver = '\''ixgbe'\'';/; ' netmap_install.pl.ORG > ${DRIVER}-netmap_install.pl
		;;
		"igb")
				echo "changing $selected_driver to igb in netmap_install.pl ... "
				sed 's/my $selected_driver.*/my $selected_driver = '\''igb'\'';/; ' netmap_install.pl.ORG > ${DRIVER}-netmap_install.pl
		;;
	esac

	# Compile the driver and leave in /tmp ...
	perl ./${DRIVER}-netmap_install.pl

	# Create directory where the driver will be available for rc.local etc.
	if [ ! -d ${DRIVERPATH} ]; then
		mkdir -p ${DRIVERPATH}
		echo made ${DRIVERPATH}
	fi

	# Find location of build.dir made by netmap_install.pl and move some where else
	NETMAPBUILDFOLDER=`echo /tmp/netmap_build_tmp_folder*`

	/bin/mv ${NETMAPBUILDFOLDER} ${NETMAPDIR}/netmap.build.dir
	
	mkdir -p	${DRIVERPATH}/${DRIVER}

	cp ${NETMAPDIR}/netmap.build.dir/netmap/LINUX/netmap.ko					${DRIVERPATH}/netmap.ko
	cp ${NETMAPDIR}/netmap.build.dir/netmap/LINUX//${DRIVER}/${DRIVER}.ko	${DRIVERPATH}/${DRIVER}/${DRIVER}.ko
fi

echo "drivers available in ${DRIVERPATH}/${DRIVER}"

DRIVERDIR=/root/files/data/drivers/

if [ ! -d "${DRIVERDIR}" ]; then
	echo mkdir -p "${DRIVERDIR}"
fi

if [ ! -d "${DRIVERDIR}/${UNAME_R}" ]; then
	/bin/cp -r /opt/netmap/${UNAME_R}  ${DRIVERDIR}
fi

echo "installation drivers is in ${DRIVERDIR}/${UNAME_R}"


