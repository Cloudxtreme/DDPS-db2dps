#!/bin/sh
#
# $Header$
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

MY_LOGFILE=/var/log/auto-install.log
VERBOSE=FALSE
DATADIR=/root/files/data/
VERBOSE=TRUE

# functions

function logit() {
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

function main()
{
	# check on how to suppress newline (found in an Oracle installation script ca 1992)
	echo="/bin/echo"
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
	while getopts v opt
	do
	case $opt in
		v)	VERBOSE=TRUE
		;;
		*)	echo "usage: $0 [-v]"
			exit
		;;
	esac
	done
	shift `expr $OPTIND - 1`

	MY_DIR=`dirname $0`

    logit "Starting $0 from /etc/rc.local"
    stat $0|logit 
	logit "running from '$MY_DIR' ... "
	cd ${MY_DIR} || {
		echo "chdir ${MY_DIR} failed"; exit 0
	}

     
    logit "  1 Apply all patches by doing an update, upgrade and a dist-upgrade"
    apt-get -y update
    apt-get -y upgrade
    apt-get -y dist-upgrade

    logit "  2 Install local packages cmod, dailybuandupdate and grouproot."
    cd      /root/files
    dpkg -i cmod_1.2-2.deb
    dpkg -i dailybuandupdate_1.7-1.deb
    dpkg -i grouproot_1.2-1.deb

    logit "3 Set DK console keyboard, xenial preseed cannot set keyboard layout, as of"
    logit "  Bug #1553147 reported by Schlomo Schapiro on 2016-03-04, this fixes it"

    sed 's/^XKBLAYOUT=.*/XKBLAYOUT="dk"/; s/^XKBVARIANT=.*/XKBVARIANT=""/' /etc/default/keyboard > /tmp/keyboard
    /bin/mv /tmp/keyboard /etc/default/keyboard
    chown root:root /etc/default/keyboard
    chmod 0644 /etc/default/keyboard
    setupcon -k -f --save

    logit "   4 Ubuntu timesyncd is fine for most purposes, but ntpd uses more"
    logit "     sophisticated techniques to constantly and gradually keep the system time on"
    logit "     track. So disable uses more sophisticated techniques to constantly and"
    logit "     gradually keep the system time on track and install ntpd"
    timedatectl set-ntp no
    apt-get -y install ntp

    logit "   5 Run each each script in install.d. This is where different hosts are being produced"
    cd install.d

    find . -type f | while read SHELLSCRIPT
    do
        bash ${SHELLSCRIPT} >> $MY_LOGFILE
    done

    logit "Installation complete, fixing rc.local ... "

    # etc - loads cut
    sed -i 's_bash /root/files/install.sh_exit 0_' /etc/rc.local

    logit "Re-boot is usually required after a dist-upgrade instead of checking just do it ... "
    /sbin/reboot

    exit 0

}

################################################################################
# Main
################################################################################

main $*


