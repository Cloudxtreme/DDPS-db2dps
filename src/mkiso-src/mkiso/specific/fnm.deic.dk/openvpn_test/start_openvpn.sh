#!/bin/bash

test -f vpn-udp-1194-fnm.deic.dk/vpn-udp-1194-fnm.deic.dk.ovpn.ORG || {
	cp vpn-udp-1194-fnm.deic.dk/vpn-udp-1194-fnm.deic.dk.ovpn vpn-udp-1194-fnm.deic.dk/vpn-udp-1194-fnm.deic.dk.ovpn.ORG
}

(
cat vpn-udp-1194-fnm.deic.dk/vpn-udp-1194-fnm.deic.dk.ovpn.ORG
echo auth-user-pass vpn-udp-1194-fnm.deic.dk/pass.txt
) > vpn-udp-1194-fnm.deic.dk/vpn-udp-1194-fnm.deic.dk.ovpn

cat << EOF > vpn-udp-1194-fnm.deic.dk/pass.txt
fnm.deic.dk
1qazxsw2
EOF

echo "searching for my public ip address ... "
myip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
echo "Public IP address before VPN: ${myip}"

echo "interfaces before VPN:"
ifconfig -a|sed '/inet/!d; /inet6/d; /127.0.0.1/d'

nohup openvpn --config vpn-udp-1194-fnm.deic.dk/vpn-udp-1194-fnm.deic.dk.ovpn --pkcs12 vpn-udp-1194-fnm.deic.dk/vpn-udp-1194-fnm.deic.dk.p12 --tls-auth vpn-udp-1194-fnm.deic.dk/vpn-udp-1194-fnm.deic.dk-tls.key    --auth-retry interact & 

echo "sleeping 10 seconds ... "
sleep 10

echo "interfaces after VPN: -- expected extra address a.b.c.42"
ifconfig -a|sed '/inet/!d; /inet6/d; /127.0.0.1/d'


echo "searching for my public ip address ... "
myip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
echo "Public IP address after VPN: ${myip}"

sleep 10

echo stopping openvpn ...
killall openvpn

echo "searching for my public ip address ... "
myip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
echo "Public IP address after VPN: ${myip}"


