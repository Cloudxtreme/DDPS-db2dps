#!/bin/bash
#
#--------------------------------------------------------------------------------------#
# The script first attempt to find any 10Gb interface and install the ixgbe driver. It
# unsuccessfull the script will search for 1Gb interfaces and install the igb driver.
#
# Finally the script will install a new /etc/rc.local which will use the drivers
#--------------------------------------------------------------------------------------#

set -e

# functions

function make_rc_local()
{
	cat << EOF

### Build /etc/rc.local with 1Gb or 10Gb drivers.

Running the function make_rc_local:

EOF

	MAX_SPEED=""
	MAX_SPEED_IFNAMES=""

	echo '  1. find all interfaces and their speed assuming that nothing runs slower than 1Gb using `lshw`.'

	for SPEED in "1Gbit/s" "10Gbit/s"
	do
		IFNAMES=`lshw -C network 2>/dev/null | egrep 'capacity:|logical name:' | sed 's/.*://' | while read string
		do
			line="$line $string"
			case $string in
				"$SPEED")	echo $INTERFACE
				;;
				*"bit/s")	INTERFACE=""
				;;
				*)	INTERFACE=$string
				;;
			esac
		done`
		IFNAMES="`echo $IFNAMES`"

		NUMBERS_FOUND=`echo $IFNAMES | wc -w |tr -d ' '`
		case $NUMBERS_FOUND in 
			0)	echo "     Found $NUMBERS_FOUND interfaces running $SPEED"
			;;
			*)	echo "     Found $NUMBERS_FOUND interfaces running $SPEED: $IFNAMES"
				case $MAX_SPEED in
				"") MAX_SPEED="$SPEED"
					MAX_SPEED_IFNAMES="$IFNAMES"
				;;
				*)	:
				esac
			;;
		esac
	done

	case $MAX_SPEED in
		"")	echo "    no 10Gb or 1Gb interfaces found, bye"
			exit 1
		;;
		"1Gbit/s")	SPEED="1Gbit/s"
					DRIVER="igb"
		;;
		"10Gbit/s")	SPEED="10Gbit/s"
					DRIVER="ixgbe"
		;;
		*)	echo "max speed: $MAX_SPEED on $MAX_SPEED_IFNAMES unknown driver, bye"
			exit 0
		;;
	esac

	echo "     Speed: ${MAX_SPEED}, driver: ${DRIVER}, interfaces: ${MAX_SPEED_IFNAMES}"

	echo '  2. The driver must match the kernel, we compile drivers and store them '
	echo '     in `/opt/netmap/ kernel vesion / driver name / ...`'

	UNAME_R=`uname -r`
	DRIVERPATH=/opt/netmap/${UNAME_R}/${DRIVER}/LINUX

	# Full path to drivers
	NETMAP_KO=${DRIVERPATH}/netmap.ko
	IGB_KO=${DRIVERPATH}/${DRIVER}/${DRIVER}.ko

	IFNAMES="`echo ${MAX_SPEED_IFNAMES}`"

	NUMBERS_FOUND=`echo $IFNAMES | wc -w |tr -d ' '`
	case $NUMBERS_FOUND in 
		0)	echo "     Found $NUMBERS_FOUND interfaces running $SPEED"
			exit 1
		;;
		*)	echo "     Found $NUMBERS_FOUND interfaces running $SPEED: $IFNAMES"
		;;
	esac

	for I in ${IFNAMES}
	do
		IPADDR_ASSIGNED=`ifconfig $I |sed '/inet6/d; /inet/!d'|wc -l| tr -d ' '`
		case $IPADDR_ASSIGNED in
		0)	IFNAME=$I
			break
		;;
		*)	:
		;;
		esac
	done

	# Now build rc.local and /etc/network/interface.d/interface files

	echo '  3. The script searches for the first interface with no ip configuration'
	echo '     and bilds `/etc/rc.local` (existing will be removed) and '
	echo '     the interface definition (`/etc/network/interface.d/interface`).'

	if [ -z "${IFNAME}" ]; then
		echo "failed to find free interface, bye"
		exit 0
	else
		echo "     Interface \`${IFNAME}\` is unassigned and capable of running $SPEED ... "
	fi

	echo "     Creating \`/etc/network/interfaces.d/$IFNAME\` with network defenitons"

	echo '  4. Create an executable `/ec/rc.local` which loads the driver.'
	cat <<-EOF > /etc/network/interfaces.d/$IFNAME
# $IFNAME: $SPEED monitor interface is configured with no IP and in promiscuous mode
	auto $IFNAME
	iface $IFNAME inet manual
	up ifconfig $IFNAME up
	up ip link set $IFNAME promisc on
	down ip link set $IFNAME promisc off
	down ifconfig $IFNAME down
EOF


	cat <<-EOF | sed "s/_DRIVER_/${DRIVER}/" > /etc/rc.local
	#!/bin/sh -e
	#
	# rc.local
	#
	# This script is executed at the end of each multiuser runlevel.
	# Make sure that the script will "exit 0" on success or any other
	# value on error.
	#
	# In order to enable or disable this script just change the execution
	# bits.
	#
	# By default this script does nothing.
	#

	# DRIVER=ixgbe
	# DRIVER=igb
	DRIVER=_DRIVER_

	UNAME=`uname -r`
	DRIVERPATH=/opt/netmap/\${UNAME}/\${DRIVER}/LINUX/

	NETMAP=\${DRIVERPATH}/netmap.ko
	DRVR=\${DRIVERPATH}/\${DRIVER}/\${DRIVER}.ko

	IFNAME=${IFNAME}

	if [ -f "\${NETMAP}" -a -f "\${DRVR}" ]; then
		# Make sure that netmap is loaded for 10 Gbits igb driver:
		/sbin/ifconfig    \${IFNAME} -promisc
		/sbin/ifconfig    \${IFNAME} down
		/sbin/modprobe    ptp
		/sbin/modprobe    dca
		/sbin/rmmod       \${DRVR}
		/sbin/insmod      \${NETMAP}
		/sbin/modprobe    vxlan
		/sbin/insmod      \${DRVR}
		/sbin/ifconfig    \${IFNAME} up
		/sbin/ifconfig    \${IFNAME} promisc

		sleep 60

		# Disable various properties for fast performance in FastNetMon:
		/sbin/ethtool -K ${IFNAME} gro off gso off tso off lro off
		/sbin/ethtool -A ${IFNAME} rx off tx off

	else
		:
		# Please re-compile drivers for your current kernel
	fi

	exit 0
EOF

	chmod 755 /etc/rc.local

	echo '  5. If the drivers are not allready in `/opt/netmap/ kernel version`'
	echo '     (e.g. this is a first time installation) then the pre-compiled drivers are '
	echo '     copied from `/root/files/data/drivers/ ...` to `/opt/netmap/... `'

	DRIVERDIR=/root/files/data/drivers/

	if [ ! -d "/opt/netmap/${UNAME_R}" ]; then
		if [ -d  "${DRIVERDIR}/${UNAME_R}" ]; then
			cp -rv "${DRIVERDIR}/${UNAME_R}" "/opt/netmap/${UNAME_R}"
		else
			echo "No drivers found for ${UNAME_R} in ${DRIVERDIR}, please run"
			echo "`pwd`/ compile-and-install-igb-and-ixgbe-drivers.sh"
		fi
		else
			echo ''
			echo "Drivers installed in /opt/netmap/${UNAME_R}"
	fi

}

function compile_and_install_igb_and_ixgbe_drivers_with_netmap_patches()
{
	cat <<-'EOF'

### Compile and install Pavel Odintsov
	
Compiling igb drivers for FastNetMon and make IP config files. Save in
/opt/netmap-`kernel version`-`compile-time`/`driver`/ e.g:
e.g.
	/opt/netmap/4.4.0-87-generic/igb
	/opt/netmap/4.4.0-87-generic/ixgbe

It sould be used together with /erc/rc.local and 
/etc/network/interfaces.d/`interface name used by fastnetmon`

The valid interface config file and rc.local will be written here:
/root/files/data/developent/`driver name`

The build dir(s) will be stored in /opt/netmap-`kernel version`-`compile-time` e.g:
/opt/netmap-4.4.0-87-generic-2017-08-08-igb/netmap.build.dir
/opt/netmap-4.4.0-87-generic-2017-08-08-ixgbe/netmap.build.dir

Compilation will be made with Pavel Odintsov perl script

EOF

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

		test -d /root/files/data/developent/compile_drivers || {
			mkdir -p /root/files/data/developent/compile_drivers
		}
		cd /root/files/data/developent/compile_drivers

		echo working in `pwd` ...

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

}

function main()
{

	compile_and_install_igb_and_ixgbe_drivers_with_netmap_patches igb
	compile_and_install_igb_and_ixgbe_drivers_with_netmap_patches ixgbe
	make_rc_local
}

################################################################################
# main
################################################################################

main $*

exit 0

# Markdown documentation:
# sed '/^#:/!d; s/^#://' $0
