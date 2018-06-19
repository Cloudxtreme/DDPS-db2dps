#!/bin/bash
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
PREFIX=/root/files
MYDIR=`dirname $0`
DATADIR=${MYDIR}/data/
VERBOSE=FALSE
TMPFILE=`tempfile`

export DEBIAN_FRONTEND=noninteractive

# functions
function logit() {
# purpose     : Timestamp output
# arguments   : Line og stream
# return value: None
# see also    :
	LOGIT_NOW="`date '+%H:%M:%S (%d/%m)'`"
	STRING="$*"

	if [ -n "${STRING}" ]; then
        $echo "${LOGIT_NOW} ${STRING}"
	else
		while read LINE
		do
			if [ -n "${LINE}" ]; then
                $echo "${LOGIT_NOW} ${LINE}"
			fi
		done
	fi
}

function savefile()
{
	if [ ! -f "$1" ]; then
		echo "program error in function savefile, file '$1' not found"
		exit 0
	fi
	if [ ! -f "$1".org ]; then
		logit "function savefile: saving original $1 as $1.org ... "
		cp "$1" "$1".org
	fi
}

# purpose     : Change case on word
# arguments   : Word
# return value: GENDER=word; GENDER=`toLower $GENDER`; echo $GENDER
# see also    :
function toLower() {
	echo $1 | tr "[:upper:]" "[:lower:]"
}

function toUpper() {
	echo $1 | tr  "[:lower:]" "[:upper:]"
}


function assert () {
# purpose     : If condition false then exit from script with appropriate error message.
# arguments   : 
# return value: 
# see also    : e.g.: condition="$a -lt $b"; assert "$condition" "explaination"

    E_PARAM_ERR=98 
    E_ASSERT_FAILED=99 
    if [ -z "$2" ]; then        #  Not enough parameters passed to assert() function. 
        return $E_PARAM_ERR     #  No damage done. 
    fi  
    if [ ! "$1" ]; then 
   	# Give name of file and line number. 
        echo "Assertion failed:  \"$1\" File \"${BASH_SOURCE[1]}\", line ${BASH_LINENO[0]}"
		echo "	$2"
        exit $E_ASSERT_FAILED 
    # else 
    #   return 
    #   and continue executing the script. 
    fi  
}

function config_unassigned_virtualbox_interface()
{
	local HOSTNAME=ddps-dev

	local IPV4ADDR=192.168.99.10
	local IPV4MASK=255.255.255.0
	local IPV4NET=192.168.99.1
	local IPV4BC=192.168.99.255

	# list of interfaces
	local IFNAMES=`ifconfig -a|sed '/Link.*HWaddr.*/!d; s/Link.*//; s/ *//'`

	# interface with no address
	local IFNAME=""

	for I in ${IFNAMES}
	do
		local IPADDR_ASSIGNED=`ifconfig $I |sed '/inet6/d; /inet/!d'|wc -l| tr -d ' '`
		case $IPADDR_ASSIGNED in
		0)	IFNAME=$I
		;;
		*)	:
		;;
		esac
	done

	if [ -z "${IFNAME}" ]; then
        logit "No free interface (ok if not specific CD image)"
		return 1
	else
		logit "using interface name ${IFNAME} ... "
	fi

	cat << EOF > /etc/network/interfaces.d/$IFNAME
	# The primary network interface
	auto $IFNAME
	iface $IFNAME inet static
		address $IPV4ADDR
		netmask $IPV4MASK
		network $IPV4NET
		broadcast $IPV4BC
		# gateway $IPV4GW
		# dns-* options are implemented by the resolvconf package, if installed
		# dns-nameservers $DNS
		# dns-search $DOM
		### Ubuntu Linux add persistent route command ###
		$ROUTE
EOF

	cat << EOF > /etc/hosts
	127.0.0.1	localhost
	127.0.1.1	$HOSTNAME

	# The following lines are desirable for IPv6 capable hosts
	::1     localhost ip6-localhost ip6-loopback
	ff02::1 ip6-allnodes
	ff02::2 ip6-allrouters
EOF

	echo $HOSTNAME > /etc/hostname
	chmod 644 /etc/network/interfaces /etc/hosts /etc/hostname

	systemctl restart systemd-logind.service
	hostnamectl set-hostname $HOSTNAME
	ifdown	$IFNAME
	ifup	$IFNAME
	service networking restart
	/etc/init.d/networking force-reload
}

function install_build_essential()
{
	# for make to work
	apt-get -y install build-essential autoconf

	# for postgres backup to work:
	/bin/cp ${DATADIR}/cfg/bin/autopgsqlbackup /usr/local/bin/autopgsqlbackup
	chmod 555 /usr/local/bin/autopgsqlbackup
	chown root:root /usr/local/bin/autopgsqlbackup

	echo "$0: installing configuration files ... "
	for FILE in ${DATADIR}/cfg/etc/daily_backup.cfg ${DATADIR}cfg/etc/daily_backup.files
	do
		echo "$0: installing /usr/local/etc/$FILE  ... "
		/bin/cp $FILE /usr/local/etc/
	done
}

function install_local_packages()
{
    logit "Install local packages ... "
    for PKG in $DATADIR/deb/*deb
    do
        dpkg -i $PKG > $TMPFILE
        case $? in
            0)  logit "installed $PKG"
                ;;
            *)  logit "failed install $PKG:"
                logit < $TMPFILE
                ;;
        esac
    done
}	

function apply_patches()
{
    logit "running apt-get -y update, upgrade dist-upgrade ... "
    ( apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade ) > $TMPFILE
	case $? in
		0)	logit "done"
		;;
		*)	logit "failed:"
		logit < $TMPFILE
		;;
	esac
}

function install_virt_what()
{
	logit "installing virt-what ... "
	apt-get -y install virt-what > $TMPFILE
    case $? in
        0)  logit "done"
            case `virt-what` in
                "vmware")	apt-get -y install open-vm-tools
                ;;
                *)			:
                ;;
            esac
            ;;
        *)  logit "failed:"
		logit < $TMPFILE
            ;;
    esac
}

function install_ntp_service()
{
    # Ubuntu timesyncd is fine for most purposes, but ntpd uses more
    # sophisticated techniques to constantly and gradually keep the system time on
    # track. So disable uses more sophisticated techniques to constantly and
    # gradually keep the system time on track and install ntpd
    logit "replacing systemd time keeping with ntp ... "
    timedatectl set-ntp no  && logit "disabled systemd based time keeping ... "
    logit "installing ntp ... "
    apt-get -y install ntp  > $TMPFILE
    case $? in
        0)  logit "done"
            ;;
        *)  logit "installation failed:"
            logit < $TMPFILE
            ;;
    esac
}

function set_dk_console_keyboard()
{
    logit "Set DK console keyboard, xenial preseed cannot set keyboard layout, as of"
    logit "Bug #1553147 reported by Schlomo Schapiro on 2016-03-04, this fixes it"

    sed 's/^XKBLAYOUT=.*/XKBLAYOUT="dk"/; s/^XKBVARIANT=.*/XKBVARIANT=""/' /etc/default/keyboard > /tmp/keyboard
    /bin/mv /tmp/keyboard /etc/default/keyboard
    chown root:root /etc/default/keyboard
    chmod 0644 /etc/default/keyboard
    setupcon -k -f --save
    logit "done"
}

function install_build_essential()
{
	# for make to work
    logit "installing build-essential and autoconf ... "
	apt-get -y install build-essential autoconf > $TMPFILE
	case $? in 
		0)	logit "done"
		;;
		*)	logit "failed build-essential autoconf:"
            logit < $TMPFILE
		;;
	esac

    logit "copy autopgsqlbackup ... "
	# for postgres backup to work:
	/bin/cp ${DATADIR}/cfg/bin/autopgsqlbackup /usr/local/bin/autopgsqlbackup
	chmod 555 /usr/local/bin/autopgsqlbackup
	chown root:root /usr/local/bin/autopgsqlbackup

	 test -f /usr/local/bin/autopgsqlbackup || {
        logit "error: file /usr/local/bin/autopgsqlbackup not found!"
    }

	logit "installing configuration files ... "
	for FILE in ${DATADIR}/cfg/etc/daily_backup.cfg ${DATADIR}cfg/etc/daily_backup.files
	do
		logit "installing /usr/local/etc/$FILE  ... "
		/bin/cp $FILE /usr/local/etc/
	done
}

function change_sshd_config()
{
	savefile /etc/ssh/sshd_config

    logit "changing sshd_config:"
	logit "  - enabled password less ssh root login ... "	
	logit "  - disabled password ssh login ... "
	logit "  - adding sftp group ... "

	# root has not set a pw, enable ssh login
	usermod -p '*' root

	(
	sed '
	   /^AllowTcpForwarding/d;
	  s/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/;
	  s/^#[ \t]*PasswordAuthentication[ \t]yes*/PasswordAuthentication no/;
	  s/^PasswordAuthentication.*/PasswordAuthentication no/;
	  s/^UsePAM.*/UsePAM no/;
	  s/\(X11Forwarding.*\)/AllowTcpForwarding yes\n\1/' < /etc/ssh/sshd_config.org
	cat << EOF
	Match Group sftpgroup
		# Force the connection to use SFTP and chroot to the required directory.
		ForceCommand internal-sftp
		ChrootDirectory %h
		# Disable tunneling, authentication agent, TCP and X11 forwarding.
		PermitTunnel no
		AllowAgentForwarding no
		AllowTcpForwarding no
		X11Forwarding no
EOF
	) > /etc/ssh/sshd_config
	chmod 0644 /etc/ssh/sshd_config
	chown root:root /etc/ssh/sshd_config
	service ssh restart
	logit "new sshd_config, ssh restarted: Login with password now prohibited"
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

    # logit "Starting $0 from /etc/rc.local"
    # stat $0|logit 

    config_unassigned_virtualbox_interface
    
    apply_patches

    install_virt_what

    install_local_packages

    install_build_essential

    set_dk_console_keyboard

    install_ntp_service

    change_sshd_config

    logit "Executing each script in install.d ...."

    cd install.d
	
    find . -type f -name '*.sh' | sort -n | while read SHELLSCRIPT
    do
        logit "executing install.d/`basename ${SHELLSCRIPT}` ... "
        bash ${SHELLSCRIPT} 2>&1 | logit
    done
    logit "Installation complete, fixing rc.local ... "

    # remove install once if ISO
    sed -i "s_bash /.*/install.sh_exit 0_" /etc/rc.local

    logit "Re-boot is usually required after a dist-upgrade instead of checking just do it ... "

	case `virt-what` in
		"vmware")	/sbin/reboot
		;;
		*)			echo "on vagrant, do vagrant halt; vagrant up"
		;;
	esac

    exit 0
}

################################################################################
# Main
################################################################################

( main $* ) 2>&1 | tee ${MY_LOGFILE} 


