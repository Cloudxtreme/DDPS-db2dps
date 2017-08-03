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

function printrule()
{
	echo "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$proto;$sport;$dport;$dport;$icmptype;$icmpcode;$tcpflags;$length;$ttl;$dscp;$fragmentencoding;$action;$description"
	src="null"
	proto="null"
	sport="null"
	dport="null"
	dport="null"
	icmptype="null"
	icmpcode="null"
	tcpflags="null"
	length="null"
	ttl="null"
	dscp="null"
	fragmentencoding="null"
	action="null"
	description="null"

}

INI=/opt/db2dps/etc/db.ini

################################################################################
#INCLUDE_VERSION_SH
################################################################################

# default values
customerid="1"
uuid="00:25:90:47:2b:48"        # <-- should be changed
fastnetmoninstanceid="1"        # <-- should be changed
administratorid="42"            # <-- should be changed
ttl="null"
sport="null"
dport="null"
dport="null"
icmptype="null"
icmpcode="null"
tcpflags="null"
length="null"
dscp="null"
fragmentencoding="null"
src="null"
action="discard"
description="Default rule"

blocktime=1

ournetworks=`sed '/^ournetworks/!d; s/^ournetworks.*=[\t ]*//'	${INI}`
#ournetworks="130.226.136.242/32"
sleeptime=`sed '/^sleep_time/!d; s/^sleep_time.*=[\t ]*//'	${INI}`

now=`/bin/date +%s`
randomstr=`tr -dc A-Za-z0-9_ < /dev/urandom | head -c 8 | xargs`

rulefile="/home/sftpgroup/newrules/upload/newrules-${uuid}-${now}-${randomstr}.dat"
tmprules="/tmp/$$.dat"


# begin
(
echo "head;fnm;noop;1;${proto}_flood"

for dst in $ournetworks;
do
	description="Default block all udp fragments"
	fragmentencoding="[is-fragment first-fragment last-fragment]"
	proto=udp
	#fragmentencoding="is-fragment"
	printrule

	description="Default discard NTP amplification"
	proto="udp"
	sport="=123"
	length="=468"
	printrule

	description="Default discard DNS amplification"
	proto="udp"
	sport="=53"
	length="=512"
	printrule

	description="Default discard TCP and UDP chargen"
	proto="=tcp =udp"
	sport="=19"
	length="null"
	printrule

	description="Default discard TCP and UDP QOTD"
	proto="=tcp =udp"
	sport="=17"
	length="null"
	printrule

	description="Default discard IP protocol 47, GRE"
	proto="=47"
	sport="null"
	length="null"
	printrule


	description="Default ratelimit SSDP"
	action="rate-limit 9600"
	proto="=udp"
	sport="1900"
	printrule

	description="Default ratelimit SNMP"
	action="rate-limit 9600"
	proto="=udp"
	sport="=161&=162"
	printrule
done

# end
echo "last-line"
) > $tmprules

/bin/mv $tmprules $rulefile
echo "rules prepared and will be applied within ${sleeptime} seconds"
echo wrote rules to $rulefile

exit 

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
