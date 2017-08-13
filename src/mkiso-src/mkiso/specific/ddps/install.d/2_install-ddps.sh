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
toLower() {
	echo $1 | tr "[:upper:]" "[:lower:]"
}

toUpper() {
	echo $1 | tr  "[:lower:]" "[:upper:]"
}


assert () {
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

function main()
{
	# check on how to suppress newline (found in an Oracle installation script ca 1992)
	echo="builtin echo"
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

	logit "running from $MY_DIR ... "
	cd ${MY_DIR} || {
		echo "chdir ${MY_DIR} failed"; exit 0
	}

	# for make to work
	apt-get -y install build-essential

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

	logit "adding developers: no password login admin rights ... "

	if [ -f ${DATADIR}/dev.lst ]; then
		OIFS=$IFS
		IFS=";"
		cat ${DATADIR}/dev.lst | while read USR GCOS ID
		do
			getent passwd ${USR} >/dev/null 2>&1 >/dev/null || adduser --uid ${ID} --home /home/${USR} --shell /bin/bash --gecos "${GCOS}" --ingroup staff --disabled-password ${USR}
			usermod -a -G sudo	${USR}
			sudo chage -d 0		${USR}
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
		locale-gen da_DK.UTF-8
	}

	logit "Append /opt/db2dps/bin and /opt/mkiso/bin to PATH ... "
	echo "PATH=$PATH:/opt/db2dps/bin:/opt/mkiso/bin" > /etc/profile.d/ddps.sh 
	chmod 644 /etc/profile.d/ddps.sh
	chown root:root /etc/profile.d/ddps.sh

	logit " modify /etc/sudoers so /opt/db2dps/bin and /opt/mkiso/bin is in PATH "
	sed 's%.*secure_path.*%Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/db2dps/bin:/opt/mkiso/bin"%'  /etc/sudoers > /tmp/sudoers
	/bin/mv /tmp/sudoers /etc/sudoers
	chmod  0440 /etc/sudoers 
	chown root:root /etc/sudoers

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

	logit "setting up sftp user for fastnetmon .... "
	getent passwd ddpsadm > /dev/null 2>&1  >/dev/null || adduser --home /home/ddpsadm --shell /bin/bash --gecos "DDPS admin" --ingroup staff --disabled-password ddpsadm
	if grep -q sftpgroup /etc/group
    then
         :
    else
		addgroup --system sftpgroup
    fi

	test -d /home/sftpgroup || mkdir /home/sftpgroup
	getent passwd newrules >/dev/null 2>&1 >/dev/null || useradd -m -c "DDPS rules upload" -d /home/sftpgroup/newrules/ -s /sbin/nologin newrules
	usermod -G sftpgroup newrules

	chown root:root /home/sftpgroup /home/sftpgroup/newrules/
	test -d /home/sftpgroup/.ssh || mkdir /home/sftpgroup/.ssh
	chmod 755 /home/sftpgroup /home/sftpgroup/newrules/

	test -d /home/sftpgroup/newrules/upload || mkdir /home/sftpgroup/newrules/upload
	chown newrules:newrules /home/sftpgroup/newrules/upload
	chmod 777 /home/sftpgroup/newrules/upload

	chattr -i /home/sftpgroup/newrules/.ssh/authorized_keys /home/sftpgroup/newrules/.ssh/
	cat << EOF | tr -d '\n' > /home/sftpgroup/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgM0xg9opRyCXvRApeRsmMT6zzZ154ligQXBF8z
HsgS root@00:25:90:46:c2:fe-fastnetmon2.deic.dk
EOF
	chown -R newrules:newrules /home/sftpgroup/.ssh
	chattr +i /home/sftpgroup/newrules/.ssh   /home/sftpgroup/newrules/.ssh/*

	logit "keys added to /home/sftpgroup/.ssh/authorized_keys change if required"

	# see https://www.postgresql.org/about/news/1432/
	logit "Installing the latest postgres database .... "

	apt-get -y update

	logit "adding PPA to /etc/apt/sources.list.d/pgdg.list ... "
	logit "adding keys ... "
	logit "installing postgresql ... "
	echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list

	cat << EOF > /etc/apt/preferences.d/pgdg.pref
Package: *
Pin: release o=apt.postgresql.org
Pin-Priority: 500
EOF

	wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
	apt-get -y install postgresql postgresql-contrib libpq-dev

	logit "installed postgresql version: "
	pg_config --version 2>&1 |logit
	logit "expected output: PostgreSQL 9.6.1 or later"
	psql --version 2>&1 |logit
	logit "expected output: psql (PostgreSQL) 9.6.1 or later"

	logit "chaning postgres config file ... "

	# 9.4, 9.5, 9.6 ... pick the latest
	PG_HBACONF=`ls -1 /etc/postgresql/*/main/pg_hba.conf|sort -n | tail -1`

	logit "config file: ${PG_HBACONF}"
	savefile "${PG_HBACONF}"
	awk '
	{
		if ($1 == "local" && $2 == "all" && $3 == "postgres")
		{
			print $0
			print "local all flowuser peer"
			print "local all dbadmin md5"
			next
		}
		{ print; next; }
	}'	${PG_HBACONF}.org >	${PG_HBACONF}

	chmod 0640 ${PG_HBACONF}
	chown postgres:postgres ${PG_HBACONF}
	service postgresql restart

	logit "NOT creating database .... "

	logit "EITHER restore an existing database made with"
	echo "cd /; echo 'pg_dumpall | gzip -9 > /tmp/netflow.dmp.sql.gz' | su postgres "
	echo "using "
	echo "cd /; gunzip netflow.dmp.sql.gz"
	echo "echo 'psql -d postgres -f /tmp/netflow.dmp.sql' |  su postgres"
	logit "OR"
	logit "execute commands from below: (should be in /root/files/data/db"
	cat << EOF | logit
	echo 'psql -f db/1_create_netwlow_db.sql'             | su postgres	
	echo 'psql -f db/2_create_netflow_schema.sql'         | su postgres
	echo 'psql netflow -f db/netflow_flow.icmp_codes.sql' | su postgres
	echo 'psql netflow -f db/netflow_flow.icmp_types.sql' | su postgres
	echo 'psql netflow -f db/netflow_flow.protocols.sql'  | su postgres
	echo 'psql netflow -f db/netflow_flow.services.sql'   | su postgres

	logit "connect with "
	logit "ssh -v -L 5432:127.0.0.1:5432 sysadm@ddps-dev"

EOF

	logit "all done"

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

