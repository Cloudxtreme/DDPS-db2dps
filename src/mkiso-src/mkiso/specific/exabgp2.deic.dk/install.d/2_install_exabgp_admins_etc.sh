#!/bin/bash
#
# DeIC DPS: development database server installation 
#
# Pre-requisite for the development environment:
# virtualbox or similar
# Ubuntu server 16.04 with an sshd server, no automatic update
# preferably two net cards, one with internet access for updates etc.
# and one for (static) connecting from the development environment

MY_LOGFILE=/var/log/install-ddps.log
VERBOSE=FALSE
DATADIR=/root/files/data/

# functions
function savefile()
{
	if [ ! -f "$1" ]; then
		echo "program error in function savefile, file '$1' not found"
		exit 0
	fi
	if [ ! -f "$1".org ]; then
		logit "saving original $1 as $1.org ... "
		cp "$1" "$1".org
	fi
}

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

function install_build_essential()
{
	# for make to work
	apt-get -y install build-essential git

	# for postgres backup to work:
	/bin/cp ${DATADIR}/cfg/bin/autopgsqlbackup /usr/local/bin/autopgsqlbackup
	chmod 555 /usr/local/bin/autopgsqlbackup
	chown root:root /usr/local/bin/autopgsqlbackup

	logit "installing configuration files ... "
	for FILE in ${DATADIR}/cfg/etc/daily_backup.cfg ${DATADIR}cfg/etc/daily_backup.files
	do
		logit "installing /usr/local/etc/$FILE  ... "
		/bin/cp $FILE /usr/local/etc/
	done

	# should not be required as the system has just been patched by install.sh ...
	apt-get -y update
	apt-get -y upgrade
	apt-get -y dist-upgrade

	cd /usr/local/src
	git clone git://git.annexia.org/git/virt-what.git
	cd virt-what
	autoreconf -i
	autoconf
	./configure
	make install

	case `/usr/local/sbin/virt-what` in
		"vmware")	apt-get -y install open-vm-tools
		;;
		*)			:
		;;
	esac
}

function add_developers()
{

	logit "adding developers: no password login admin rights ... "

	if [ -f ${DATADIR}/dev.lst ]; then
		OIFS=$IFS
		IFS=";"
		cat ${DATADIR}/dev.lst | while read USR GCOS ID KEY
		do
			logit "adding user ${USR} ... "
			getent passwd ${USR} >/dev/null 2>&1 >/dev/null || adduser --uid ${ID} --home /home/${USR} --shell /bin/bash --gecos "${GCOS}" --ingroup staff --disabled-password ${USR}
			usermod -a -G sudo	${USR}
			sudo chage -d 0		${USR}
			mkdir -p /home/${USR}/.ssh
			echo "$KEY" > /home/${USR}/.ssh/authorized_keys
			chown -R ${USR} /home/${USR}/.ssh/
			chmod 700 /home/${USR}/.ssh /home/${USR}/.ssh/*
			logit "done"
		done
	else
		logit "no developers added. Add dev.lst with the following syntax:"
		logit "\"username\" \"full name\" \"numeric user id\" "
	fi
	IFS=$OIFS

	logit "setting sudo without password ... "
	echo '%sudo	ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/sudogrp
	chmod 0440 /etc/sudoers.d/sudogrp

	grep ^da_DK /etc/locale.gen >/dev/null  || {
		logit "installing locale da_DK.UTF-8 .... "
		locale-gen en_DK.utf8
		locale-gen da_DK.UTF-8
	}

	logit "Append /opt/db2dps/bin and /opt/mkiso/bin to PATH ... "
	echo "PATH=\$PATH:/opt/db2dps/bin:/opt/mkiso/bin" > /etc/profile.d/ddps.sh 
	chmod 644 /etc/profile.d/ddps.sh
	chown root:root /etc/profile.d/ddps.sh

	logit "modify /etc/sudoers so /opt/db2dps/bin and /opt/mkiso/bin is in PATH "
	sed 's%.*secure_path.*%Defaults	secure_path="/bin:/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/opt/db2dps/bin:/opt/mkiso/bin:/opt/pgpool2/bin"%' /etc/sudoers > /tmp/sudoers
	/bin/mv /tmp/sudoers /etc/sudoers
	chmod  0440 /etc/sudoers 
	chown root:root /etc/sudoers

}

function change_sshd_config()
{
	savefile /etc/ssh/sshd_config

	# root has no pw, enable ssh login
	logit "enabling password less ssh root login ... "	
	logit "disabling password ssh login ... "
	logit "adding sftp group ... "
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

function make_sftp_user()
{
	logit "installing ddpsadm user .... "
	getent passwd ddpsadm > /dev/null 2>&1  >/dev/null || adduser --home /home/ddpsadm --shell /bin/bash --gecos "DDPS admin" --ingroup staff --disabled-password ddpsadm

	logit "adding sftpgroup .... "
	if grep -q sftpgroup /etc/group
    then
         :
    else
		addgroup --system sftpgroup
    fi

	if [ -f /home/sftpgroup/newrules/.ssh/authorized_keys ]; then
		chattr -i /home/sftpgroup/newrules/.ssh/authorized_keys /home/sftpgroup/newrules/.ssh/	>/dev/null 2>&1
		rm -fr /home/sftpgroup/																	>/dev/null 2>&1
		userdel -r newrules																		>/dev/null 2>&1
		logit "removed existing user newrules"
	fi

	mkdir /home/sftpgroup; chown root:root /home/sftpgroup

	logit "setting up sftp user for fastnetmon .... "
	getent passwd newrules >/dev/null 2>&1 >/dev/null || useradd -m -c "DDPS rules upload" -d /home/sftpgroup/newrules/ -s /sbin/nologin newrules
	usermod -G sftpgroup newrules

	chmod 755          /home/sftpgroup /home/sftpgroup/newrules/
	mkdir -p           /home/sftpgroup/newrules/.ssh
	chmod 700          /home/sftpgroup/newrules/.ssh
	chown -R root:root /home/sftpgroup /home/sftpgroup/newrules/

	test -d /home/sftpgroup/newrules/upload || mkdir /home/sftpgroup/newrules/upload
	chown newrules:newrules /home/sftpgroup/newrules/upload
	chmod 777 /home/sftpgroup/newrules/upload

	logit "permissions for /home/sftpgroup has been set carefully, dont change"
	logit "use chattr to lock / unlock /home/sftpgroup/newrules/.ssh/authorized_keys"

	chattr -i /home/sftpgroup/newrules/.ssh/
	if [ -f /home/sftpgroup/newrules/.ssh/authorized_keys ]; then
		chattr -i /home/sftpgroup/newrules/.ssh/authorized_keys
	fi
	# this is a dummy key
	cat << EOF | tr -d '\n' > /home/sftpgroup/newrules/.ssh/authorized_keys
ssh-ed25519 AAAAC3NIamAdummyKeyJustToSeIfaScriptWorkspeRsmMT6zzZ154ligQXBF8zHsgS root@00:25:90:46:c2:fe-fastnetmon2.deic.dk
EOF
	chown -R newrules:newrules /home/sftpgroup/newrules/.ssh
	chattr +i /home/sftpgroup/newrules/.ssh   /home/sftpgroup/newrules/.ssh/*

	logit "dummy key added to /home/sftpgroup/.ssh/authorized_keys"
}

function install_exabgp()
{

    logit "installing exabgp and socat .... "
    apt-get -y install exabgp socat
    logit "installing configuration files ... "
    /bin/cp /root/files/data/exabgp/* /etc/exabgp/
    mkdir               /run/exabgp
    chown exabgp:exabgp /run/exabgp/
    chmod 755           /run/exabgp/
    service exabgp stop
    service exabgp start
    systemctl is-active exabgp 

    # required for access from ddps
    mkdir /root/.ssh
    cat << 'EOF' > /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/EolcoPvI67izK9wV/oyPP7iDOxUcvnYpc1DI2sBhHhDOrA19yS3FiLikrCyNfEf3nkJrVbuxMi+RjPJ4TU/VexQsVJzAdJl6hFgpBR/raZ5mBjKOZkbRFToKn9k1A1CqAroXurfQmiLi8KwG1SjDbqijts1ew4X9qxvduYdwZRKGU318W2ixkfiXn5G8BHgSR6qfdTjMJZxNYRnlstlvJ6V5cz8g2KudhntvNveDjX8CU6rTO0/aaB+R47qM5zDTgtTzk5LPguOMAHF/abYY6XsBdDybjiU6AXsayP/yhppbUkI4skqVIPe0Ey3aWZkSfIW3DU9hDF/jKK6NMQpR root@fodhost
EOF
    chmod -R 700 /root/.ssh

    # rc.local fix for exabgp 
    cat << EOF > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

mkdir /run/exabgp
chown exabgp:exabgp /run/exabgp/
service exabgp restart

exit 0
EOF
    chmod 555 /etc/rc.local
    chown root /etc/rc.local

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

	logit "running from '$MY_DIR' ... "
	cd ${MY_DIR} || {
		echo "chdir ${MY_DIR} failed"; exit 0
	}

	install_build_essential
	
	add_developers

	change_sshd_config

    install_exabgp

	logit "all done"

	exit 0

	USR_LIST=`sed '/nologin$/d; /false$/d; s/:.*//' /etc/passwd`
	USR_LIST=`echo $USR_LIST`

	logit "WARNING: do not log out without adding your public ssh keys to .ssh/authorized_keys"
	logit "for one of the users $USR_LIST"

	exit 0
}

################################################################################
# Main
################################################################################

main $*

