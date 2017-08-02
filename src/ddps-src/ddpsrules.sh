#!/bin/bash
#
# Ad-hoc tool
#


function to_int {
    local -i num="10#${1}"
    echo "${num}"
}
 
function valid_portnr {
    local port="$1"
	if [ "$port" = "null" ]; then return 0; fi
    local -i port_num=$(to_int "${port}" 2>/dev/null)
 
    if (( $port_num < 1 || $port_num > 65535 )) ; then
        return 1
    fi
    return 0
}

function valid_cidr()
#      valid_cidr IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#      if valid_cidr IP_ADDRESS; then echo good; else echo bad; fi
{
    local  ip=$1
    local  stat=1

    # if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    if [[ $ip =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function print_active_rules()
{
	q_active_rules="select
		flowspecruleid,
		--direction,
		destinationprefix,
		sourceprefix,
		ipprotocol,
		--srcordestport,
		destinationport,
		--sourceport,
		--icmptype,
		--icmpcode,
		--tcpflags,
		--packetlength,
		--dscp,
		--fragmentencoding,
		--action,
		--validfrom,
		validto
	from
		flow.flowspecrules,
		flow.fastnetmoninstances
	where
		flow.flowspecrules.fastnetmoninstanceid = flow.fastnetmoninstances.fastnetmoninstanceid
		AND not isexpired
		--AND not isactivated
		AND mode = 'enforce'
	order by
		validto DESC,
		validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding
		;
	"
	echo "---------------------------------------------------------------------------------------------------------------------"
	echo "Active rules"
	echo "---------------------------------------------------------------------------------------------------------------------"

	echo "$q_active_rules" |/usr/bin/psql -h ${DBHOST} -U ${USR} -v ON_ERROR_STOP=1 -w -d ${DB} 

	return 0
}

##################################################################
#INCLUDE_VERSION_SH
##################################################################

##################################################################
# main
##################################################################

function main()
{
	INI=/opt/db2dps/etc/db.ini
	DBHOST="127.0.0.1"
	USR=`sed '/^dbuser/!d; s/dbuser[\t ]*=//' ${INI}`
	PW=`sed '/^dbpassword/!d; s/dbpassword[\t ]*=//' ${INI}`
	DB=`sed '/^dbname/!d; s/dbname[\t ]*=//' ${INI}`
	USR="postgres"

 	case $1 in
		"-V")
			cat <<-EOF
			version:	${version}
			build_date	${build_date}
			build_git_sha	${build_git_sha}
EOF
			exit
		;;
		"-h")	cat << EOF

Simple cli based ad-hoc rule interface with NO IMPUT VALIDATION

usage: $0 [-V | -h] [add | del | print] ... 

-V:
	Print version information and exit
-h:
	Help

add:
	$0 add src dst proto sport dport icmptype icmpcode TCP-flags length fragmentencoding blocktime

	- use 'null' for whildcard fields
	- protocol:         0-255 or well known name (first field in /etc/protocols)
	- src, dst:         One IPv4 address only in CIDR format (database value limitation)
	- s/dport:          source / destination port (0-65535)
	- icmp type/code:   value between 0-255
	- length:           value between 64-65535
	- TCP-flags:        cwr ece urg ack psh rst syn fin
	- fragmentencoding: is-fragment or null
	- blocktime:        minutes e.g. hour/day/week: 600 1440 10080

    Action should match either accept, discard or rate-limit 9600

	Rules will be added as customer '1' administrator '42' and a random
	picked fastnetmon identy

	Enforcement may be monitored with 

		grep rulebase /var/log/syslog|grep -v 0

del:
	del flowspecruleid

	The rule with flowspecruleid will have expire set to now, thereby being withdrawn

print:

	Print the current active rules

EOF
			exit
		;;
		"add")
			shift; src="${1}";
			shift; dst="${1}";
			shift; proto="${1}";
			shift; sport="${1}";
			shift; dport="${1}";
			shift; icmptype="${1}";
			shift; icmpcode="${1}";
			shift; tcpflags="${1}";
			shift; length="${1}";
			shift; fragmentencoding="${1}";
			shift; blocktime="${1}";

			test -z "${src}"				&& { echo "src missing"; exit; }
			test -z "${dst}"				&& { echo "dst missing"; exit; }
			test -z "${proto}"				&& { echo "proto missing"; exit; }
			test -z "${sport}"				&& { echo "sport missing"; exit; }
			test -z "${dport}"				&& { echo "dport missing"; exit; }
			test -z "${icmptype}"			&& { echo "icmptype missing"; exit; }
			test -z "${icmpcode}"			&& { echo "icmptype missing"; exit; }
			test -z "${tcpflags}"			&& { echo "tcpflags missing"; exit; }
			test -z "${length}"				&& { echo "length missing"; exit; }
			test -z "${fragmentencoding}"	&& { echo "fragmentencoding missing"; exit; }
			test -z "${blocktime}"			&& { echo "blocktime missing"; exit; }

			# check for the worst errors and mistakes
			case $proto in
				"null")	:
					;;
				*) if ! grep -q ${proto} /etc/protocols; then echo proto $protocol not valid; exit; fi
					;;
			esac

			if ! valid_cidr ${src}; then echo src ${src} is not a valid cidr; exit ; fi
			if ! valid_cidr ${dst}; then echo dst ${dst} is not a valid cidr; exit ; fi

			if ! valid_portnr ${sport}; then echo sport ${sport} is not a valid port; exit ; fi
			if ! valid_portnr ${dport}; then echo sport ${dport} is not a valid port; exit ; fi

			case $tcpflags in
				"cwr"|"ece"|"urg"|"ack"|"psh"|"rst"|"syn"|"fin"|"null")
					:
				;;
				*)	echo "tcpflags $tcpflags not valid"
					exit
				;;
			esac

			if (( $length < 64 || $length > 65535 )) ; then
				echo "length is lower than the minimum ethernet frame or larger than the maximum frame"
				exit
			fi

			case $fragmentencoding in
				"is-fragment"|"null")
					:
				;;
				*)	echo "fragmentencoding $fragmentencoding not valid"
					exit
				;;
			esac

			if [ "$blocktime" -gt 0 ]; then
				:
			else
				echo "blocktime $blocktime not valid"
				exit
			fi

			# sorry a grusome hack -- this has to be rewritten in perl
			allmynetworks=`sed '/^ournetworks.*=/!d; s/^.*=//; s/^[\t ]*//' /opt/db2dps/etc/db.ini`
			cat << 'EOF' | sed "s%_allmynetworks%$allmynetworks%g" >/tmp/p.pl
#!/usr/bin/perl -w

my $dst="$ARGV[0]";
use NetAddr::IP;
$allmynetworks = "_allmynetworks";
my $destinationprefix_is_within_my_network = 1;

my $dst_subnet = new NetAddr::IP $dst;
foreach my $mynetwork (split ' ', $allmynetworks)
{
	 $subnet = new NetAddr::IP $mynetwork;
	 if ($dst_subnet->within($subnet))
	{
		$destinationprefix_is_within_my_network = 0;
	}
}
print $destinationprefix_is_within_my_network; 
EOF
			chmod 700 /tmp/p.pl

			case `/tmp/p.pl $dst` in
				0)	:
					;;
				*)	echo "destination $dst is not part of out network"; exit
				;;
			esac
			/bin/rm -f /tmp/p.pl

			customerid="1"
			uuid="00:25:90:47:2b:48"		# <-- should be changed
			fastnetmoninstanceid="1"		# <-- should be changed
			administratorid="42"			# <-- should be changed
			ttl="null"
			dscp="null"
			whoami=`whoami`
			if [ "${whoami}" = "root" ]; then
				description="command line rule made by ${whoami} - `last -w -1 -a| awk ' NR==1 { print $1 \" login from \" $NF }'`"
			else
				description="command line rule made by `getent passwd ${whoami}|awk -F':' '{ print $1 " / " $5}'`"
			fi

			cat <<-EOF
Block the following
--------------------------------------------------------------------------------
src:                $src
dst:                $dst
proto:              $proto
sport:              $sport
dport:              $dport
icmptype:           $icmptype
icmpcode:           $icmpcode
TCP-flags:          $tcpflags
length:             $length
fragmentencoding:   $fragmentencoding
blocktime:          $blocktime
action:             $action
description:        $description
--------------------------------------------------------------------------------
Please notice that there is no check if the above is valid in any way: feel free
to mix icmptypes with the tcp protocol and portnumbers. The result is unknown.

EOF
			echo -n "ok ? [yep]"
			read ans

			# print to a new rulefile
			proto=`egrep -iv ipv6 /etc/protocols |awk '$1 == "'${proto}'" || $2 == "'${proto}'" || $3 == "'${proto}'" { print $1 }'`
			now=`/bin/date +%s`
			randomstr=`tr -dc A-Za-z0-9_ < /dev/urandom | head -c 8 | xargs`
			rulefile="/home/sftpgroup/newrules/upload/newrules-${uuid}-${now}-${randomstr}.dat"
			sudo cat <<-EOF > $rulefile
head;fnm;doop;1;${proto}_flood
$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$proto;$sport;$dport;$dport;$icmptype;$icmpcode;$tcpflags;$length;$ttl;$dscp;$fragmentencoding;$action;$description
last-line
EOF
		echo saved as $rulefile
		echo will be read by db2dps and enforced shortly, bye
		exit
		;;
		"del")
			shift; flowspecruleid="${1}";
			test -z "${flowspecruleid}"			&& { echo "flowspecruleid missing"; exit; }

			q_withdraw_rule="update flow.flowspecrules set validto=now() where flowspecruleid in ( ${flowspecruleid} );"
			echo "$q_withdraw_rule" |/usr/bin/psql -h ${DBHOST} -U ${USR} -v ON_ERROR_STOP=1 -w -d ${DB} 
		;;
		"print")
			print_active_rules
			exit
		;;
		*)	echo "usage: $0 [add | del | print] ... "
			exit
		;;
	esac 
}

main $*

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
