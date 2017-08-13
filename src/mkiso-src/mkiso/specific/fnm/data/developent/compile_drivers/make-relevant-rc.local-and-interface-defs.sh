#!/bin/sh
#
#--------------------------------------------------------------------------------------#
#:
#:### Script documentation
#:
#:This requires compile-and-install-igb-and-ixgbe-drivers.sh has been run successfully
#:and will create two files: an interface definition and rc.local with commands for 
#:loading the relevant driver.           
#:The script first attempt to find any 10Gb interface and install the ixgbe driver. It
#:unsuccessfull the script will search for 1Gb interfaces and install the igb driver
#--------------------------------------------------------------------------------------#
set -e

MAX_SPEED=""
MAX_SPEED_IFNAMES=""

#:
#:  1. find all interfaces and their speed assuming that nothing runs slower than 1Gb
#:     using `lshw`.
#
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
		0)	echo "Found $NUMBERS_FOUND interfaces running $SPEED"
		;;
		*)	echo "Found $NUMBERS_FOUND interfaces running $SPEED: $IFNAMES"
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
	"")	echo "no 10Gb or 1Gb interfaces found, bye"
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

echo "Speed: ${MAX_SPEED}, driver: ${DRIVER}, interfaces: ${MAX_SPEED_IFNAMES}"

#
#:  2. The driver must match the kernel, we compile drivers and store them 
#:     in `/opt/netmap/ kernel vesion / driver name / ...`
#
UNAME_R=`uname -r`
DRIVERPATH=/opt/netmap/${UNAME_R}/${DRIVER}/LINUX

# Full path to drivers
NETMAP_KO=${DRIVERPATH}/netmap.ko
IGB_KO=${DRIVERPATH}/${DRIVER}/${DRIVER}.ko

IFNAMES="`echo ${MAX_SPEED_IFNAMES}`"

NUMBERS_FOUND=`echo $IFNAMES | wc -w |tr -d ' '`
case $NUMBERS_FOUND in 
	0)	echo "Found $NUMBERS_FOUND interfaces running $SPEED"
		exit 1
	;;
	*)	echo "Found $NUMBERS_FOUND interfaces running $SPEED: $IFNAMES"
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
#
#:  3. The script searches for the first interface with no ip configuration
#:     and bilds `/etc/rc.local` (existing will be removed) and 
#:     the interface definition (`/etc/network/interface.d/interface`).

if [ -z "${IFNAME}" ]; then
	echo "failed to find free interface, bye"
	exit 0
else
	echo "${IFNAME} is unassigned and capable of running $SPEED ... "
fi

cat << EOF > /etc/network/interfaces.d/$IFNAME
# $IFNAME: $SPEED monitor interface is configured with no IP and in promiscuous mode
	auto $IFNAME
	iface $IFNAME inet manual
	up ifconfig $IFNAME up
	up ip link set $IFNAME promisc on
	down ip link set $IFNAME promisc off
	down ifconfig $IFNAME down
EOF

echo "made /etc/network/interfaces.d/$IFNAME"

cat << EOF | sed "s/_DRIVER_/${DRIVER}/" > /etc/rc.local
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

#:  4. Next `/ec/rc.local` is made executable.

chmod 755 /etc/rc.local
echo "made /etc/rc.local"

#
#:  5. If the drivers are not allready in `/opt/netmap/ kernel version`
#:     (e.g. this is a first time installation) then the pre-compiled drivers are 
#:     copied from `/root/files/data/drivers/ ...` to `/opt/netmap/... `
#
DRIVERDIR=/root/files/data/drivers/

if [ ! -d "/opt/netmap/${UNAME_R}" ]; then
	if [ -d  "${DRIVERDIR}/${UNAME_R}" ]; then
		cp -rv "${DRIVERDIR}/${UNAME_R}" "/opt/netmap/${UNAME_R}"
	else
		echo "No drivers found for ${UNAME_R} in ${DRIVERDIR}, please run"
		echo "`pwd`/ compile-and-install-igb-and-ixgbe-drivers.sh"
	fi
	else
		echo "drivers allready installed in /opt/netmap/${UNAME_R}"
fi

exit 0

# Markdown documentation:
# sed '/^#:/!d; s/^#://' $0
