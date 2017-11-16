#!/bin/bash
#

INI=/opt/db2dps/etc/db.ini
ournetworks=`sed '/^ournetworks/!d; s/^ournetworks.*=[\t ]*//'	${INI}`

YEAR=365
MIN=60
DAY=24
BLKTME=`echo "$YEAR * $DAY * $MIN"| bc`

for DST in $ournetworks
do
    ddpsrules add -y --blocktime $BLKTME --dst $DST --protocol 'udp' --frag '[is-fragment first-fragment last-fragment]' --action 'discard' -e 'block all UDP fragments' >/dev/null
    ddpsrules add -y --blocktime $BLKTME --dst $DST --protocol 'udp' --sport '=123' --length='=468'--action 'discard' -e 'Discard NTP amplification' >/dev/null >/dev/null
    ddpsrules add -y --blocktime $BLKTME --dst $DST --protocol 'udp' --sport '=53' --length='=512'--action 'discard' -e 'Discard DNS amplification' >/dev/null
    ddpsrules add -y --blocktime $BLKTME --dst $DST --protocol '=tcp =udp' --sport '=19' --action 'discard' -e 'Discard TCP and UDP chargen' >/dev/null
    ddpsrules add -y --blocktime $BLKTME --dst $DST --protocol '=tcp =udp' --sport '=17' --action 'discard' -e 'Discard TCP and UDP QOTD' >/dev/null
    ddpsrules add -y --blocktime $BLKTME --dst $DST --protocol '=47' --action 'discard' -e 'Discard IP protocol 47, GRE' >/dev/null
    ddpsrules add -y --blocktime $BLKTME --dst $DST --protocol '=udp' --sport '=1900' --action 'rate-limit 9600' -e 'ratelimit SSDP' >/dev/null
    ddpsrules add -y --blocktime $BLKTME --dst $DST --protocol '=udp' --sport '=161&=162' --action 'rate-limit 9600' -e 'ratelimit SNMP' >/dev/null

    sleep 3
	ddpsrules active

done

exit

#
# apply rules to mitigate icmp flooding of antispam networks for nearly one year 31536000 (60 * 60 * 24 * 365)
#

	ddpsrules add -y --blocktime '31536000' --dst '130.225.242.144/28' --protocol 'icmp' --action 'rate-limit 9600' 
	ddpsrules add -y --blocktime '31536000' --dst '130.226.249.32/29'  --protocol 'icmp' --action 'rate-limit 9600'
	ddpsrules add -y --blocktime '31536000' --dst '130.226.249.48/29'  --protocol 'icmp' --action 'rate-limit 9600'

#
# View result interactively, exit with ctrl-c
#

	watch ddpsrules active

#
# Remove all active rules
#
	ddpsrules del `ddpsrules active|awk '$1 ~ /[0-9]/ { print $1}'`

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
