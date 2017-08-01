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

################################################################################
#INCLUDE_VERSION_SH
################################################################################

customerid="1"
uuid="00:25:90:47:2b:48"        # <-- should be changed
fastnetmoninstanceid="1"        # <-- should be changed
administratorid="42"            # <-- should be changed
ttl="null"

ournetworks=`sed '/^ournetworks/!d; s/^ournetworks.*=[\t ]*//'	${INI}`

# discard-udp-fragments
proto=udp
blocktime=1
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
src="null"
action="discard"
description="Default rule"

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
	fragmentencoding="is-fragment"
	echo "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$proto;$sport;$dport;$dport;$icmptype;$icmpcode;$tcpflags;$length;$ttl;$dscp;$fragmentencoding;$action;$description"
	fragmentencoding="null"

	description="Default discard NTP amplification"
	proto="udp"
	sport="=123"
	length="=468"
	echo "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$proto;$sport;$dport;$dport;$icmptype;$icmpcode;$tcpflags;$length;$ttl;$dscp;$fragmentencoding;$action;$description"

	description="Default discard DNS amplification"
	proto="udp"
	sport="=53"
	length="=512"
	echo "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$proto;$sport;$dport;$dport;$icmptype;$icmpcode;$tcpflags;$length;$ttl;$dscp;$fragmentencoding;$action;$description"

	description="Default discard TCP and UDP chargen"
	proto="=tcp =udp"
	sport="=19"
	length="null"
	echo "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$proto;$sport;$dport;$dport;$icmptype;$icmpcode;$tcpflags;$length;$ttl;$dscp;$fragmentencoding;$action;$description"

	description="Default discard TCP and UDP QOTD"
	proto="=tcp =udp"
	sport="=17"
	length="null"
	echo "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$proto;$sport;$dport;$dport;$icmptype;$icmpcode;$tcpflags;$length;$ttl;$dscp;$fragmentencoding;$action;$description"

	description="Default discard IP protocol 47, GRE"
	proto="=47"
	sport="null"
	length="null"
	echo "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$proto;$sport;$dport;$dport;$icmptype;$icmpcode;$tcpflags;$length;$ttl;$dscp;$fragmentencoding;$action;$description"


	Default="Default ratelimit SSDP"
	action="rate-limit 9600"
	proto="=udp"
	sport="1900"
	echo "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$proto;$sport;$dport;$dport;$icmptype;$icmpcode;$tcpflags;$length;$ttl;$dscp;$fragmentencoding;$action;$description"

	Default="Default ratelimit SNMP"
	action="rate-limit 9600"
	proto="=udp"
	sport="=161&=162"
	echo "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$proto;$sport;$dport;$dport;$icmptype;$icmpcode;$tcpflags;$length;$ttl;$dscp;$fragmentencoding;$action;$description"
done

# end
echo "last-line"
) > $tmprules

ls $tmprules

#/bin/mv $tmprules $rulefile

echo wrote rules to $rulefile

exit 
