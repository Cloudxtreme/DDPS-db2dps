#!/bin/sh
#
# fnm-dev
#
# Add static IPv4 address to interface with no assigned IP. This
# is only required in our VirtualBox test environment, where the
# guest has default gateway behind the NAT interface, and access
# to that interface is not possible.
# The address should be on the host-only adapter.
#

IPV4ADDR=192.168.99.100
IPV4MASK=255.255.255.0
IPV4NET=192.168.99.0
IPV4BC=192.168.99.255

if (grep -q ^flags.*\ hypervisor /proc/cpuinfo); then
    echo -n "This machine is a VM: "
    dmidecode -s bios-version | grep VirtualBox
else
    echo "will not assign ${IPV4ADDR} to interface"
    exit 0
fi

exit 0

# list of interfaces
# IFNAMES=`ifconfig -a|sed '/Link.*HWaddr.*/!d; s/Link.*//; s/ *//'`	# Ubuntu
IFNAMES=`ifconfig -a| sed '/flags=.*/!d; /^lo/d; s/: flags=.*//g'`

# interface with no address
IFNAME=""

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

if [ -z "${IFNAME}" ]; then
	echo "failed to find free interface, bye"
	exit 0
else
	echo "using interface name ${IFNAME} ... "
fi

cat << EOF > /etc/network/interfaces.d/$IFNAME
# The primary network interface
auto $IFNAME
iface $IFNAME inet static
	address $IPV4ADDR
	netmask $IPV4MASK
	network $IPV4NET
	broadcast $IPV4BC
	# gateway $IPV4GW
	# dns-* options are implemented by the resolvconf package, if installed
	# dns-nameservers $DNS
	# dns-search $DOM
	### Ubuntu Linux add persistent route command ###
	$ROUTE
EOF

# this doesnt work
systemctl restart systemd-logind.service
ifdown	$IFNAME
ifup	$IFNAME
service networking restart
/etc/init.d/networking force-reload
# this does

#/sbin/reboot
