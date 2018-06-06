#!/bin/bash
#

DATADIR=/root/files/data/

# functions
function savefile()
{
	if [ ! -f "$1" ]; then
		echo "program error in function savefile, file '$1' not found"
		exit 0
	fi
	if [ ! -f "$1".org ]; then
		echo "$0: saving original $1 as $1.org ... "
		cp "$1" "$1".org
	fi
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

function add_developers()
{

	echo "$0: adding developers: no password login admin rights ... "

	if [ -f ${DATADIR}/dev.lst ]; then
		OIFS=$IFS
		IFS=";"
		cat ${DATADIR}/dev.lst | while read USR GCOS ID KEY
		do
			echo "$0: adding user ${USR} ... "
			getent passwd ${USR} >/dev/null 2>&1 >/dev/null || adduser --uid ${ID} --home /home/${USR} --shell /bin/bash --gecos "${GCOS}" --ingroup staff --disabled-password ${USR}
			usermod -a -G sudo	${USR}
			sudo chage -d 0		${USR}
			mkdir -p /home/${USR}/.ssh
			echo "$KEY" > /home/${USR}/.ssh/authorized_keys
			chown -R ${USR} /home/${USR}/.ssh/
			chmod 700 /home/${USR}/.ssh /home/${USR}/.ssh/*
			echo "$0: done"
		done
	else
		necho "$0:o developers added. Add dev.lst with the following syntax:"
		echo "$0: \"username\" \"full name\" \"numeric user id\" "
	fi
	IFS=$OIFS

	echo "$0: setting sudo without password ... "
	echo '%sudo	ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/sudogrp
	chmod 0440 /etc/sudoers.d/sudogrp

	grep ^da_DK /etc/locale.gen >/dev/null  || {
		echo "$0: installing locale da_DK.UTF-8 .... "
		locale-gen en_DK.utf8
		locale-gen da_DK.UTF-8
	}

	echo "$0: Append /opt/db2dps/bin and /opt/mkiso/bin to PATH ... "
	echo "PATH=\$PATH:/opt/db2dps/bin:/opt/mkiso/bin" > /etc/profile.d/ddps.sh 
	chmod 644 /etc/profile.d/ddps.sh
	chown root:root /etc/profile.d/ddps.sh

	echo "$0: modify /etc/sudoers so /opt/db2dps/bin and /opt/mkiso/bin is in PATH "
	sed 's%.*secure_path.*%Defaults	secure_path="/bin:/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/opt/db2dps/bin:/opt/mkiso/bin:/opt/pgpool2/bin"%' /etc/sudoers > /tmp/sudoers
	/bin/mv /tmp/sudoers /etc/sudoers
	chmod  0440 /etc/sudoers 
	chown root:root /etc/sudoers

}

function change_sshd_config()
{
	savefile /etc/ssh/sshd_config

	# root has no pw, enable ssh login
	echo "$0: enabling password less ssh root login ... "	
	echo "$0: disabling password ssh login ... "
	echo "$0: adding sftp group ... "
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
}

function setup_database()
{

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

	echo "$0: running from '$MY_DIR' ... "
	cd ${MY_DIR} || {
		echo "chdir ${MY_DIR} failed"; exit 0
	}
	
	add_developers

	echo "$0:all done"

	exit 0

	USR_LIST=`sed '/nologin$/d; /false$/d; s/:.*//' /etc/passwd`
	USR_LIST=`echo $USR_LIST`

	echo "$0: ARNING: do not log out without adding your public ssh keys to .ssh/authorized_keys"
	echo "$0: for one of the users $USR_LIST"

	exit 0
}

################################################################################
# Main
################################################################################

main $*

