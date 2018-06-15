#! /bin/bash
# A poor mans static DDoS protection system in 42 lines of shell code
#   Copyright 2017, DeiC, Niels Thomas Haugård, apache license apply

INI=/opt/db2dps/etc/db.ini

DST=`sed '/^ournetworks/!d; s/^ournetworks.*=[\t ]*//'	${INI}`
EXABGPHOSTS=`sed '/^hostlist/!d; s/^.*=[\t ]*//'		${INI}`
EXABGPHOSTS=localhost

################################################################################
#INCLUDE_VERSION_SH
################################################################################

case $1 in
	"announce"|"withdraw")	DO="$1 flow route "
	;;
	*)	echo "usage $0 announce | withdraw"
		exit
	;;
esac

for EXAHOST in ${EXABGPHOSTS}
do
	for D in $DST
	do
		cat <<-EOF | sed '/^#/d;' | ssh root@${EXAHOST} 'cat > /var/run/exabgp/exabgp.cmd'
		${DO} default-discard-udp-fragments { match { destination ${D}; protocol udp; fragment [ is-fragment first-fragment last-fragment ]; } then { discard } }
		${DO} default-discard-ntp-amplification { match { destination ${D}; protocol udp; source-port =123; packet-length =468; } then { discard } }
		${DO} default-discard-dns-amplification { match { destination ${D}; protocol udp; source-port =53; packet-length =512; } then { discard } }
		${DO} default-discard-dns-amplification { match { destination ${D}; protocol udp; source-port =53; } then { discard } }
		${DO} default-discard-chargen { match { destination ${D}; protocol udp; source-port =19; } then { discard } }
		${DO} default-discard-chargen { match { destination ${D}; protocol tcp; source-port =19; } then { discard } }
		${DO} default-discard-QOTD { match { destination ${D}; protocol udp; source-port =17; } then { discard } }
		${DO} default-discard-QOTD { match { destination ${D}; protocol tcp; source-port =17; } then { discard } }
		${DO} default-discard-gre { match { destination ${D}; protocol =47; source-port =17; } then { discard } }
		${DO} default-ratelimit-SSDP { match { destination ${D}; protocol udp; source-port =1900 } then { rate-limit 9600; } }
		${DO} default-ratelimit-snmp { match { destination ${D}; protocol udp; source-port =161 =162; } then { rate-limit 9600; } }
EOF
	done
done
exit 0

#
#   Copyright 2017, DeiC, Niels Thomas Haugård
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# This script is part of DDPS but not used in production
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
#
# Assumes you have one or more exabgp instances for announcements
#
# Destination networks (DST) has the format 
# 	ournetworks = a.b.c.d/e f.g.h.i/j
# The list of exabgp hosts (EXABGPHOSTS) has the format
#      hostlist = 1.2.3.4 5.6.7.8
#
