#! /bin/bash
#
# Static BGP flowspec filter which will reduce the attack vector:
# The filter will deny the following traffic passing the core routers:
# UDP Fragment
# DNS replies larger than 512 bytes
# NTP monlist reply packets with the maximum 6 IP addresses populated in the payload
# CHARGEN
# SSDP (Simple Service Discovery Protocol on UDP port 1900)
# SNMP
# sources: http://nabcop.org/index.php/DDoS-DoS-attack-BCOP 
# https://www.akamai.com/us/en/multimedia/documents/state-of-the-internet/q4-2016-state-of-the-internet-security-report.pdf

# Our networks
D="destination 95.128.24.0/21 130.225.0.0/16 130.226.0.0/16 185.1.57.0/24 192.38.0.0/17"

# Our BGP entry points
EXABGPHOSTS="exabgp1 exabgp2"

case $1 in
	"announce"|"withdraw")	DO="$1 flow route "
	;;
	*)	echo "usage $0 announce | withdraw"
		exit
	;;
esac

for E in ${EXABGPHOSTS}
do
	cat << EOF | sed '/^#/d;' | ssh root@${E} 'cat > /var/run/exabgp/exabgp.cmd'
	${DO} default-discard-udp-fragments { match { $D; protocol udp; fragment [ is-fragment first-fragment last-fragment ]; } then { discard } }
	${DO} default-discard-ntp-amplification { match { $D; protocol udp; source-port =123; packet-length =468; } then { discard } }
	${DO} default-discard-dns-amplification { match { $D; protocol udp; source-port =53; packet-length =512; } then { discard } }
	${DO} default-discard-dns-amplification { match { $D; protocol udp; source-port =19; } then { discard } }
	${DO} default-discard-chargen { match { $D; protocol udp; source-port =19; } then { discard } }
	${DO} default-discard-chargen { match { $D; protocol tcp; source-port =19; } then { discard } }
	${DO} default-discard-QOTD { match { $D; protocol udp; source-port =17; } then { discard } }
	${DO} default-discard-QOTD { match { $D; protocol tcp; source-port =17; } then { discard } }
	${DO} default-ratelimit-SSDP { match { $D; protocol udp; source-port =1900 } then { rate-limit 9600; } }
	${DO} default-ratelimit-snmp { match { $D; protocol udp; source-port =161&=162; } then { rate-limit 9600; } }
EOF
done
