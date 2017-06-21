#!/bin/sh
#
# NTH
#
# Add static IPv4 addr to interface with no assigned IP
# Set hostname 

HOSTNAME=ddps-dev

IPV4ADDR=192.168.99.10
IPV4MASK=255.255.255.0
IPV4NET=192.168.99.1
IPV4BC=192.168.99.255

# list of interfaces
IFNAMES=`ifconfig -a|sed '/Link.*HWaddr.*/!d; s/Link.*//; s/ *//'`

# interface with no address
IFNAME=""

for I in ${IFNAMES}
do
	IPADDR_ASSIGNED=`ifconfig $I |sed '/inet6/d; /inet/!d'|wc -l| tr -d ' '`
	case $IPADDR_ASSIGNED in
	0)	IFNAME=$I
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

cat << EOF > /etc/hosts
127.0.0.1	localhost
127.0.1.1	$HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

echo $HOSTNAME > /etc/hostname
chmod 644 /etc/network/interfaces /etc/hosts /etc/hostname

# this doesnt work
systemctl restart systemd-logind.service
hostnamectl set-hostname $HOSTNAME
ifdown	$IFNAME
ifup	$IFNAME
service networking restart
/etc/init.d/networking force-reload
# this does

#/sbin/reboot
