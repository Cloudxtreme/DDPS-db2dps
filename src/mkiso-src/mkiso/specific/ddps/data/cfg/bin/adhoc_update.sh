#!/bin/bash
#
# $Header$
#
#--------------------------------------------------------------------------------------#
# TODO
#
#--------------------------------------------------------------------------------------#


#
# Vars
#
MY_LOGFILE=/var/log/adhoc_update.log
VERBOSE=FALSE
CHECKONLY=FALSE
TMPFILE=/tmp/${MYNAME}.tmp

export PATH=/bin:/etc:/sbin:/usr/bin:/usr/bin/X11:/usr/local/bin:/usr/local/etc:/usr/local/sbin:/usr/sbin:/usr/lib
export DEBIAN_FRONTEND=noninteractive

#
# Functions
#
function run_apt_get()
{
        do=$1
        tmpfile=/tmp/$$.tmp.$$.tmp

        if [ -z "${do}" ]; then
                logit "in function run_apt_get: called without argument, bye"
                exit
        fi
		logit "apt-get $do ... "
        /usr/bin/apt-get -y $do > $tmpfile 2>&1
		if [[ $? > 0 ]]; then
				echo fatal: apt-get $do failed
                logit "apt-get $do failed:"
                logit  < $tmpfile
                /bin/rm -f $tmpfile
                logit "proceding anyway ... "
		else
				if egrep -q "^W: Failed to fetch|^Err http"  $tmpfile
				then
					logit "apt-get $do failed:"
                	logit  < $tmpfile
                	/bin/rm -f $tmpfile
					logit "proceding anyway ... "
				else
                	logit apt-get $do done ok
				fi
		fi
        /bin/rm -f $tmpfile
}

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
			$echo "${LOGIT_NOW} ${STRING}"
		fi
	else
		while read LINE
		do
			if [ -n "${LINE}" ]; then
				$echo "${LOGIT_NOW} ${LINE}" >> ${MY_LOGFILE}
				if [ "${VERBOSE}" = "TRUE" ]; then
					$echo "${LOGIT_NOW} ${LINE}"
				fi
			else
				$echo "" >> ${MY_LOGFILE}
			fi
		done
	fi
}

clean_f () {
# purpose     : Clean-up on trapping (signal)
# arguments   : None
# return value: None
# see also    :
	$echo trapped
	/bin/rm -f $TMPFILE $MAILFILE
	exit 1
}

#
# clean up on trap(s)
#
trap clean_f 1 2 3 13 15

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
while getopts cv opt
do
case $opt in
	v)	VERBOSE=TRUE
	;;
	c)	CHECKONLY=TRUE
	;;
	*)	echo "usage: `basename $0` [-cv]"
		echo "     -c: check only"
		echo "     -v: verbose"
		exit
	;;
esac
done
shift `expr $OPTIND - 1`

logit "starting $0 $*"

# fix any expired keys
(
	for K in $(apt-key list | grep expired | cut -d'/' -f2 | cut -d' ' -f1); do sudo apt-key adv --recv-keys --keyserver keys.gnupg.net $K; done
) 2>&1 | logit

run_apt_get update

apt-get --just-print upgrade 2>&1 | awk '
$1 == 0 { next }	# 0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded
$1 != "Inst" { next; }
{
	gsub(/\[/, "", $0);
	gsub(/\]/, "", $0);
	gsub(/\(/, "", $0);
	gsub(/\)/, "", $0);
	printf("Upgrade: %30-s\tFrom: %30s\tTo: %30s\n", $2, $3, $4)
	next
}' | logit

case $CHECKONLY in
	"TRUE")	logit upgrade check done
			exit
	;;
	"FALSE") logit done. Proceding with upgrade and dist-upgrade and autoremove
	;;
esac

#| /usr/bin/perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "PROGRAM: $1 INSTALLED: $2 AVAILABLE: $3\n"}' | logit

# sometimes upgrade fails so run this:
dpkg --configure -a

run_apt_get upgrade
run_apt_get dist-upgrade
run_apt_get autoremove
run_apt_get clean

if [ -f /var/run/reboot-required ]; then
        logit reboot required - reboot in 60 seconds
        sleep 60
        reboot
else
        logit reboot not required normal exit
fi
exit 0

#
# Documentation and  standard disclaimar
#
# Copyright (C) 2001 Niels Thomas Haugård
# UNI-C
# http://www.uni-c.dk/
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
#++
# NAME
#	adhoc_update.sh 1
# SUMMARY
#	Adhoc baseret opdatering af debian og ubuntu
# PACKAGE
#	backup-and-patch
# SYNOPSIS
#	adhoc_update.sh [-v][c]
# BESKRIVELSE
#	\fCadhoc_update.sh(1)\fR laver følgende:
# .IP o
#	\fCapt-get update\fR
# .IP o
#	\fCapt-get upgrade\fR
# .IP o
#	\fCapt-get dist-upgrade\fR
#
#	Hvis et reboot er nødvendigt udføres det også.
#
# OPTIONS
#	Kaldes \fCadhoc_update.sh\fR med flaget
# .TP
#	\fC-c\fR
#	Laves blot et check af, hvad der kan opdateres
# .TP
#	\fC-v\fR
#	Pringes loginfo til skærmen.
# SE OGSÅ
#	Dokumentationen for UNIbackup.
# DIAGNOSTICS
#	Ingen.
# BUGS
#	Det er der sikkert.
# VERSION
#	$Date: 2003/08/13 13:40:31 $
# .br
#	$Revision: 1.17 $
# .br
#	$Source: /lan/ssi/projects/adhoc_update/src/RCS/adhoc_update.sh,v $
# .br
#	$State: Exp $
# HISTORY
#	Se \fCrlog\fR $Id: adhoc_update.sh,v 1.17 2003/08/13 13:40:31 admin Exp $
# AUTHOR(S)
#	Niels Thomas Haugård
# .br
#	E-mail: thomas@haugaard.net
# .br
#	UNI\(buC
# .br
#	DTU, Building 304
# .br
#	DK-2800 Kgs. Lyngby
#--
