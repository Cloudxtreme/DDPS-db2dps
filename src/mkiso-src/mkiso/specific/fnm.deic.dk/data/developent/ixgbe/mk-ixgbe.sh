#!/bin/sh
#
# $Header$
#
#--------------------------------------------------------------------------------------#
# Compiling and installing ixgbe drivers for FastNetMon
#--------------------------------------------------------------------------------------#

# test if /opt/netmap/LINUX/netmap.ko exist and is a file or else

# should be one of e1000e igb ixgbe:
#	/opt/netmap/`uname -r`/1000e/LINUX/netmap.ko
#	/opt/netmap/`uname -r`/igb/LINUX/netmap.ko
#	/opt/netmap/`uname -r`/ixgbe/LINUX/netmap.ko

UNAME_R=`uname -r`

IGBPATH=/opt/netmap/${UNAME_R}/igb/LINUX

IXGBEPATH=/opt/netmap/${UNAME_R}/ixgbe/LINUX

NETMAP_KO=${IXGBEPATH}/netmap.ko
IXGBE_KO=${IXGBEPATH}/ixgbe/ixgbe.ko

if [ -e ${NETMAP_KO} -a -e ${IXGBE_KO} ]; then
	echo "found ${NETMAP_KO} and ${IXGBE_KO}  ok"
else
	wget -N https://gist.githubusercontent.com/pavel-odintsov/6353bfd3bfd7dba2d99a/raw/f8b0e15ef203b343d846e17be9dfec25db1172e3/netmap_install.pl
	/bin/mv netmap_install.pl netmap_install.pl.ORG

	NOW=`date '+%Y-%m-%d'`
	NETMAPDIR=/opt/netmap-${UNAME_R}-${NOW}-ixgbe/

	mkdir -p $NETMAPDIR

	echo "changing $selected_driver to ixgbe in netmap_install.pl ... "
	sed 's/my $selected_driver.*/my $selected_driver = '\''ixgbe'\'';/; ' netmap_install.pl.ORG > netmap_install.pl

	perl ./netmap_install.pl

	if [ ! -d ${IXGBEPATH} ]; then
		mkdir -p ${IXGBEPATH}
		echo made ${IXGBEPATH}
	fi

	NETMAPBUILDFOLDER=`echo /tmp/netmap_build_tmp_folder*`

	/bin/mv ${NETMAPBUILDFOLDER} ${NETMAPDIR}/netmap.build.dir
	
	mkdir -p	${IXGBEPATH}/ixgbe

	cp ${NETMAPDIR}/netmap.build.dir/netmap/LINUX/netmap.ko			${IXGBEPATH}/netmap.ko
	cp ${NETMAPDIR}/netmap.build.dir/netmap/LINUX//ixgbe/ixgbe.ko	${IXGBEPATH}/ixgbe/ixgbe.ko

fi


# find 10Gb interface logical name with no assigned address
INTERFACE=`lshw -C network 2>/dev/null | egrep 'capacity:|logical name:|serial:' | awk '
		BEGIN { logical = ""; serial = ""; capacity = ""; found = 0; ifname = ""; ifserial = ""  }
		{
				if ($1 == "logical")	{ logical = $3 ; next }
				if ($1 == "serial:")    { serial = $2 ; next }
				if ($1 == "capacity:")	{ capacity = $2; }
				if ($2 ~ /10Gbit/)		{ print logical; next }
		}
		'`

#INTERFACE=enp0s9

INTERFACE=`echo $INTERFACE`
if [ -z "${INTERFACE}" ]; then
	#for I in INTERFACE check if has addresses and skip, else use first
else
	# no suitable interfaces found, bye
fi

exit 0

TODO: fix below

if [ -n "${INTERFACE}" ]; then

cat << EOF > /etc/rc.local
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

NETMAP_KO=${IXGBEPATH}/netmap.ko
IXGBE_KO=${IXGBEPATH}/ixgbe/ixgbe.ko

INTERFACE=${INTERFACE}

# Make sure that netmap is loaded for 10 Gbits ixgbe driver:
/sbin/ifconfig	\${INTERFACE} -promisc
/sbin/ifconfig	\${INTERFACE} down
/sbin/rmmod		ixgbe
/sbin/insmod	\${NETMAP_KO}
/sbin/modprobe	vxlan
/sbin/insmod	\${IXGBE_KO}
/sbin/ifconfig	\${INTERFACE} up
/sbin/ifconfig	\${INTERFACE} promisc

sleep 60

# Disable various properties for fast performance in FastNetMon:
/sbin/ethtool -K ${INTERFACE} gro off gso off tso off lro off
/sbin/ethtool -A ${INTERFACE} rx off tx off

exit 0
EOF

# add /etc/network/interfaces.d/${INTERFACE} info
cat << EOF > /etc/network/interfaces.d/${INTERFACE}
# ${INTERFACE} 10 Gbips monitor interface is configured with no IP and in promiscuous mode
auto ${INTERFACE}
iface ${INTERFACE} inet manual
		up ifconfig ${INTERFACE} up
		up ip link set ${INTERFACE} promisc on
		down ip link set ${INTERFACE} promisc off
		down ifconfig ${INTERFACE} down
EOF

else
	echo "no 10Gbit/s interface found, /etc/rc.local not changed"
fi

exit 0

