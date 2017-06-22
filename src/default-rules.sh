#! /bin/bash
#
# This static BGP flowspec filter will deny the following traffic passing the core routers:
# 	- UDP Fragments
#	- DNS replies larger than 512 bytes
#	- NTP monlist reply packets with the maximum 6 IP addresses populated in the payload
#	- CHARGEN
#	- SSDP (Simple Service Discovery Protocol on UDP port 1900)
#	- SNMP
#
# idea from http://nabcop.org/index.php/DDoS-DoS-attack-BCOP, conversation with Nordunet and
# https://www.akamai.com/us/en/multimedia/documents/state-of-the-internet/q4-2016-state-of-the-internet-security-report.pdf

INI=/opt/db2dps/etc/db.ini

DST=`sed '/^ournetworks/!d; s/^ournetworks.*=[\t ]*//'	${INI}`
EXABGPHOSTS=`sed '/^hostlist/!d; s/^.*=[\t ]*//'		${INI}`

case $1 in
	"announce"|"withdraw")	DO="$1 flow route "
	;;
	*)	echo "usage $0 announce | withdraw"
		exit
	;;
esac

for EXAHOST in ${EXABGPHOSTS}
do
	cat << EOF | sed '/^#/d;' | ssh root@${EXAHOST} 'cat > /var/run/exabgp/exabgp.cmd'
	${DO} default-discard-udp-fragments { match { ${DST}; protocol udp; fragment [ is-fragment first-fragment last-fragment ]; } then { discard } }
	${DO} default-discard-ntp-amplification { match { ${DST}; protocol udp; source-port =123; packet-length =468; } then { discard } }
	${DO} default-discard-dns-amplification { match { ${DST}; protocol udp; source-port =53; packet-length =512; } then { discard } }
	${DO} default-discard-dns-amplification { match { ${DST}; protocol udp; source-port =19; } then { discard } }
	${DO} default-discard-chargen { match { ${DST}; protocol udp; source-port =19; } then { discard } }
	${DO} default-discard-chargen { match { ${DST}; protocol tcp; source-port =19; } then { discard } }
	${DO} default-discard-QOTD { match { ${DST}; protocol udp; source-port =17; } then { discard } }
	${DO} default-discard-QOTD { match { ${DST}; protocol tcp; source-port =17; } then { discard } }
	${DO} default-discard-gre { match { ${DST}; protocol =47; source-port =17; } then { discard } }
	${DO} default-ratelimit-SSDP { match { ${DST}; protocol udp; source-port =1900 } then { rate-limit 9600; } }
	${DO} default-ratelimit-snmp { match { ${DST}; protocol udp; source-port =161&=162; } then { rate-limit 9600; } }
EOF
done
