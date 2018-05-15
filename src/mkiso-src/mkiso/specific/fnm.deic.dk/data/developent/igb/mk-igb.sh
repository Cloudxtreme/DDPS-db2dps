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
# The build dir(s) will be stored in /opt/netmap-`kernel version`-`compile-time` e.g:
# /opt/netmap-4.4.0-87-generic-2017-08-08-igb/netmap.build.dir
# /opt/netmap-4.4.0-87-generic-2017-08-08-ixgbe/netmap.build.dir
#--------------------------------------------------------------------------------------#

UNAME_R=`uname -r`

IGBPATH=/opt/netmap/${UNAME_R}/igb/LINUX

IXGBEPATH=/opt/netmap/${UNAME_R}/ixgbe/LINUX

NETMAP_KO=${IGBPATH}/netmap.ko
IGB_KO=${IGBPATH}/igb/igb.ko

if [ -e ${NETMAP_KO} -a -e ${IGB_KO} ]; then
	echo "found ${NETMAP_KO} and ${IGB_KO}  ok"
else
	wget -N https://gist.githubusercontent.com/pavel-odintsov/6353bfd3bfd7dba2d99a/raw/f8b0e15ef203b343d846e17be9dfec25db1172e3/netmap_install.pl
	/bin/mv netmap_install.pl netmap_install.pl.ORG

	NOW=`date '+%Y-%m-%d'`
	NETMAPDIR=/opt/netmap-${UNAME_R}-${NOW}-igb/

	mkdir -p $NETMAPDIR

	echo "changing $selected_driver to igb in netmap_install.pl ... "
	sed 's/my $selected_driver.*/my $selected_driver = '\''igb'\'';/; ' netmap_install.pl.ORG > netmap_install.pl

	perl ./netmap_install.pl

	if [ ! -d ${IGBPATH} ]; then
		mkdir -p ${IGBPATH}
		echo made ${IGBPATH}
	fi

	NETMAPBUILDFOLDER=`echo /tmp/netmap_build_tmp_folder*`

	/bin/mv ${NETMAPBUILDFOLDER} ${NETMAPDIR}/netmap.build.dir
	
	mkdir -p	${IGBPATH}/igb

	cp ${NETMAPDIR}/netmap.build.dir/netmap/LINUX/netmap.ko			${IGBPATH}/netmap.ko
	cp ${NETMAPDIR}/netmap.build.dir/netmap/LINUX//igb/igb.ko	${IGBPATH}/igb/igb.ko

fi


# TODO: fix mk-ixgbe so it will match this
# find 1Gb interface logical name with no assigned addresses
INTERFACE=`lshw -C network 2>/dev/null | egrep 'capacity:|logical name:|serial:' | awk '
		BEGIN { logical = ""; serial = ""; capacity = ""; found = 0; ifname = ""; ifserial = ""  }
		{
				if ($1 == "logical")	{ logical = $3 ; next }
				if ($1 == "serial:")    { serial = $2 ; next }
				if ($1 == "capacity:")	{ capacity = $2; }
				if ($2 ~ /1Gbit/)		{ print logical; next }
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

if [ "${INTERFACE}" != "NO_10Gbit_interface_on_host" ]; then

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

NETMAP_KO=${IGBPATH}/netmap.ko
IGB_KO=${IGBPATH}/igb/igb.ko

INTERFACE=${INTERFACE}

# Make sure that netmap is loaded for 10 Gbits igb driver:
/sbin/ifconfig	\${INTERFACE} -promisc
/sbin/ifconfig	\${INTERFACE} down
/sbin/rmmod		igb
/sbin/insmod	\${NETMAP_KO}
/sbin/modprobe	vxlan
/sbin/insmod	\${IGB_KO}
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

