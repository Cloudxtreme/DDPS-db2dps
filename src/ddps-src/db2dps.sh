#!/bin/sh
#
# WARNING: script in git
#
# $Id$
#
################################################################################
#
# TODO: check for ${EXABGPREBOOTED} && do a full update
#
################################################################################

#
# Vars
#
MYDIR=/home/rnd
MYNAME=`basename $0`
MY_LOGFILE=/var/tmp/${MYNAME}.log
VERBOSE=FALSE
TMPFILE=/tmp/${MYNAME}.tmp

EXABGP_HOSTS="fodhost localhost"
EXABGP_PIPE="/tmp/exabgp-cmd"

EXABGPREBOOTED=/tmp/.full-feed-required

SEMAPHORE=/tmp/.${MYNAME}.lock

#
# Functions
#
logit() {
# purpose     : Timestamp output
# arguments   : Line og stream
# return value: None
# see also    :
	LOGIT_NOW="`date '+%H:%M:%S (%d/%m)'`"
	STRING="$*"

	if [ -n "${STRING}" ]; then
		$echo "${LOGIT_NOW} ${STRING}" >> ${MY_LOGFILE}
		if [ "${VERBOSE}" = "TRUE" ]; then
			logger -p mail.crit -t ${MYNAME} "${STRING}"
			$echo "${LOGIT_NOW} ${STRING}"
		fi
	else
		while read LINE
		do
			if [ -n "${LINE}" ]; then
				$echo "${LOGIT_NOW} ${LINE}" >> ${MY_LOGFILE}
				if [ "${VERBOSE}" = "TRUE" ]; then
					logger -p mail.crit -t ${MYNAME} "${STRING}"
					$echo "${LOGIT_NOW} ${LINE}"
				fi
			else
				$echo "" >> ${MY_LOGFILE}
			fi
		done
	fi
}
usage() {
# purpose     : Script usage
# arguments   : none
# return value: none
# see also    :
echo $*
cat << EOF
	Usage: `basename $0` [-v]

	See man pages for more info.
EOF
	exit 2
}

################################################################################
# Main
################################################################################

echo=/bin/echo
case ${N}$C in
	"") if $echo "\c" | grep c >/dev/null 2>&1; then
		N='-n'
	else
		C='\c'
	fi ;;
esac

#
# Process arguments
#
while getopts mv opt
do
case $opt in
	v)	VERBOSE=TRUE
	;;
	m)	sed '/^++/,/^--/!d; /^++/d; /^--/d' $0
	;;
	*)	usage
		exit
	;;
esac
done
shift `expr $OPTIND - 1`

if [ -f "${SEMAPHORE}" ]; then
	PID=`cat ${SEMAPHORE}`
	logit "semaphore file '${SEMAPHORE}' found with pid ${PID} "
	NO=`ps -p ${PID} |grep ${MYNAME} | wc -l | tr -d ' '`
	case $NO in
		1)	logit "process running, abort"
			;;
		0)	logit "process not running, removing stale semaphore file"
			/bin/rm -f ${SEMAPHORE}
		   	;;
	esac
fi

echo $$ > ${SEMAPHORE}

logit "Enforce new rules if any ... "
#
# Enforce new rules
#
(
cat << EOF | psql -t -F' ' -A -U postgres -v ON_ERROR_STOP=1 -w -d netflow 
select
	flowspecruleid,
	-- customernetworkid,
	-- rule_name,
	-- administratorid,
	direction,
	-- validfrom,
	-- validto,
	-- fastnetmoninstanceid,
	-- isactivated,
	-- isexpired,
	destinationprefix,
	sourceprefix,
	ipprotocol,
	srcordestport,
	destinationport,
	sourceport,
	icmptype,
	icmpcode,
	tcpflags,
	packetlength,
	dscp,
	fragmentencoding

from
	flow.flowspecrules,
	flow.fastnetmoninstances
where
	flow.flowspecrules.fastnetmoninstanceid = flow.fastnetmoninstances.fastnetmoninstanceid AND
	not isactivated AND 
	mode = 'enforce';

EOF
) | while read flowspecruleid direction destinationprefix sourceprefix ipprotocol srcordestport destinationport sourceport icmptype icmpcode tcpflags packetlength dscp fragmentencoding
do
	logit "flowspecruleid=$flowspecruleid direction=$direction destinationprefix=$destinationprefix sourceprefix=$sourceprefix ipprotocol=$ipprotocol srcordestport=$srcordestport destinationport=$destinationport sourceport=$sourceport icmptype=$icmptype icmpcode=$icmpcode tcpflags=$tcpflags packetlength=$packetlength dscp=$dscp fragmentencoding=$fragmentencoding"

	#
	# New rules for exabgp
	#
	# Syntax differs depending on the protocol
	# 
	case ${ipprotocol} in
		tcp|udp)	CMD="announce flow route ${destinationprefix} { match { source any destination ${destinationprefix}; destination-port ${destinationport}; proto ${ipprotocol}; } then { discard; } } }"
		;;
		icmp) ICMP: CMD="announce flow route ${destinationprefix} { match { protocol icmp; } then { log; discard; } } }"
		;;
		*)	# TODO: missing information
					CMD="missing info for discarding ${ipprotocol}"
		;;
	esac

	for H in ${EXABGP_HOSTS}
	do
		logit "updating ${H} with ${CMD} ... "
		ssh -n ${H} "echo ${CMD} > ${EXABGP_PIPE}-${H}"
		case $? in
		0)	ERR=0	# hopefully
		;;
		*) ERR=1	# fail
		;;
		esac
	done

	#
	# Update the database so the rules will show up as enfoced
	#
	echo "update flow.flowspecrules set isactivated = TRUE where flowspecruleid = ${flowspecruleid}" | psql -U postgres -v ON_ERROR_STOP=1 -w -d netflow 
	#
	# cannot test $? on pipes, just hope everything works or re-write in perl
	#
	logit "updated database"
done

logit "enforcement done"

#
# Cleanup: select expired rules from the database and remove them from exabgp etc. 
#
logit "removing expired rules if any ... "
(
cat << EOF | psql -t -F' ' -A -U postgres -v ON_ERROR_STOP=1 -w -d netflow 

select
	flowspecruleid,
	-- customernetworkid,
	-- rule_name,
	-- administratorid,
	direction,
	-- validfrom,
	-- validto,
	-- fastnetmoninstanceid,
	-- isactivated,
	-- isexpired,
	destinationprefix,
	sourceprefix,
	ipprotocol,
	srcordestport,
	destinationport,
	sourceport,
	icmptype,
	icmpcode,
	tcpflags,
	packetlength,
	dscp,
	fragmentencoding

from
	flow.flowspecrules,
	flow.fastnetmoninstances
where
	flow.flowspecrules.fastnetmoninstanceid = flow.fastnetmoninstances.fastnetmoninstanceid AND
	isactivated AND 
	not isexpired AND
	(
		mode = 'enforce' AND now() >= validto OR
		mode = 'detect'
	);

EOF
) | while read flowspecruleid direction destinationprefix sourceprefix ipprotocol srcordestport destinationport sourceport icmptype icmpcode tcpflags packetlength dscp fragmentencoding
do
	logit "flowspecruleid=$flowspecruleid direction=$direction destinationprefix=$destinationprefix sourceprefix=$sourceprefix ipprotocol=$ipprotocol srcordestport=$srcordestport destinationport=$destinationport sourceport=$sourceport icmptype=$icmptype icmpcode=$icmpcode tcpflags=$tcpflags packetlength=$packetlength dscp=$dscp fragmentencoding=$fragmentencoding"
	#
	# Cleanup: select expired rules from the database and remove them from exabgp etc. 
	#
	case ${ipprotocol} in
		tcp|udp)	CMD="withdraw flow route ${destinationprefix}													\
						{ match { source any destination ${destinationprefix}; destination-port ${destinationport};	\
						proto ${ipprotocol}; } then { discard; } } }"
		;;
		icmp) ICMP: CMD="withdraw flow route ${destinationprefix} { match { protocol icmp; }						\
						then { log; discard; } } }"
		;;
		*)	# TODO: missing information
					CMD="missing info for discarding ${ipprotocol}"
		;;
	esac

	for H in ${EXABGP_HOSTS}
	do
		logit "updating ${H} with ${CMD} ... "
		ssh -n ${H} "echo ${CMD} > ${EXABGP_PIPE}-${H}"
		case $? in
		0)	ERR=0	# hopefully
		;;
		*) ERR=1	# fail
		;;
		esac
	done

	#
	# Update the database if ERR=0
	#
	echo "update flow.flowspecrules set isexpired = TRUE where flowspecruleid = ${flowspecruleid}" | psql -U postgres -v ON_ERROR_STOP=1 -w -d netflow 
	logit "database updated"
done

/bin/rm -f ${SEMAPHORE}

logit "expired rules done"

logit "$0 done"

exit 0


for H in ${EXABGP_HOSTS}
do
	logit "updating ${H} with ${CMD} ... "
	ssh -n ${H} "echo ${CMD} > ${EXABGP_PIPE}-${H}"
	case $? in
	0)	ERR=0	# hopefully
	;;
	*) ERR=1	# fail
	;;
	esac
done

# crontab


######
#
# Documentation and  standard disclaimar
#
# Copyright (C) 2016 Niels Thomas Haugård
# DeiC, i2, dtu.dk
# http://www.deic.dk, http://www.i2.dk, http://www.dtu.dk
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the 
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
######
++	markdown-style-man-page-below

# NAME

Database to enforcing EXAbgp modules

# SYNOPSIS

	db2dps.sh [-v]

# DESCRIPTION
``db2dps.sh`` runs once a minute from ``/etc/cron.d`` and reads
the database for new rules which must be enforced upstream. It
also reads the database for rules which has expired and must be
redrawn.

Finally, it reads the database for all rules if a semaphore
file made by any of the exabgp instances exists. The file
indicates that an exabgp instance has been restarted.

The script usually finish within 6 - 10 seconds (real time).

# OPTIONS

     -v   Verbose: print logoutput to stdout. Debug only

# FILES

     /tmp/.full-feed-required
          The semaphore file for the one or both instance of exabgp
		  requiring a full flowspec / route feed due to restart

# ENVIRONMENT

The environment _must match that of the_ **postgress user**.

Crontab entry:

        # m h  dom mon dow   command
        */1 * * * * [ /home/rnd/bin/db2dps.sh ] && /home/rnd/bin/db2dps.sh

# DIAGNOSTICS

See syslog facility ``mail.crit`` and the logfile.

# BUGS

Probably. Please report them to the group or the author.

Please notice the script is as uaually one big version 1.0 hack and
should be re-written in e.g. perl for better error handling.

# AKNOWLEDGEMENTS

[gitlab source for DeiC DPS](git@gitlab.ssi.i2.dk:uninth/fod.git)

# AUTHOR

Niels Thomas Haugård, ntha@dtu.dk, 2016

# SEE ALSO

     ExaBGP, /bin/sh, postgress, etc.

--


_DATA_

fra http://www.juniper.net/documentation/en_US/junos15.1/topics/example/routing-bgp-flow-specification-routes.html
set routing-options flow route block-10.131.1.1 match destination 10.131.1.1/32
set routing-options flow route block-10.131.1.1 match protocol icmp
set routing-options flow route block-10.131.1.1 match icmp-type echo-request
set routing-options flow route block-10.131.1.1 then discard
set routing-options flow term-order standard

fra https://www.safaribooksonline.com/library/view/juniper-mx-series/9781449358143/ch04s04.html

route flow_http_bad_source {
    match {
        source 10.0.69.0/25;
        protocol tcp;
        port http;
    }
    then {
        rate-limit 10k;
        sample;
    }
}



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
