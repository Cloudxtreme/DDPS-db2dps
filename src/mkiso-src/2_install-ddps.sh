#!/bin/bash
#
# DeIC DPS: development database server installation 
#
# Pre-requisite for the development environment:
# virtualbox or similar
# Ubuntu server 16.04 with an sshd server, no automatic update
# preferably two net cards, one with internet access for updates etc.
# and one for (static) connecting from the development environment

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
	apt-get -y install build-essential

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

function make_sftp_user()
{
	echo "$0: installing ddpsadm user .... "
	getent passwd ddpsadm > /dev/null 2>&1  >/dev/null || adduser --home /home/ddpsadm --shell /bin/bash --gecos "DDPS admin" --ingroup staff --disabled-password ddpsadm

	echo "$0: adding sftpgroup .... "
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
		echo "$0: removed existing user newrules"
	fi

	mkdir /home/sftpgroup; chown root:root /home/sftpgroup

	echo "$0: setting up sftp user for fastnetmon .... "
	getent passwd newrules >/dev/null 2>&1 >/dev/null || useradd -m -c "DDPS rules upload" -d /home/sftpgroup/newrules/ -s /sbin/nologin newrules
	usermod -G sftpgroup newrules

	chmod 755          /home/sftpgroup /home/sftpgroup/newrules/
	mkdir -p           /home/sftpgroup/newrules/.ssh
	chmod 700          /home/sftpgroup/newrules/.ssh
	chown -R root:root /home/sftpgroup /home/sftpgroup/newrules/

	test -d /home/sftpgroup/newrules/upload || mkdir /home/sftpgroup/newrules/upload
	chown newrules:newrules /home/sftpgroup/newrules/upload
	chmod 777 /home/sftpgroup/newrules/upload

	echo "$0: permissions for /home/sftpgroup has been set carefully, dont change"
	echo "$0: use chattr to lock / unlock /home/sftpgroup/newrules/.ssh/authorized_keys"

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

	echo "$0: dummy key added to /home/sftpgroup/.ssh/authorized_keys"
}

function install_postgresql()
{
	# see https://www.postgresql.org/about/news/1432/
	echo "$0: Installing the latest postgres database .... "

	echo "$0: adding PPA to /etc/apt/sources.list.d/pgdg.list ... "
	echo "$0: adding keys ... "
	echo "$0: installing postgresql ... "
	echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list

	cat << EOF > /etc/apt/preferences.d/pgdg.pref
Package: *
Pin: release o=apt.postgresql.org
Pin-Priority: 500
EOF

	wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
	apt-get -y update
	#apt-get -y install postgresql postgresql-contrib libpq-dev
    apt-get -y install postgresql-9.6 postgresql-contrib-9.6 postgresql-client-9.6 postgresql-client-common postgresql-common postgresql-server-dev-9.6 sysstat libsensors4 libpq-dev

    # Sæt pakkerne på hold:
    apt-mark hold postgresql-9.6 postgresql-client-9.6 postgresql-client-common postgresql-common postgresql-contrib-9.6 postgresql-server-dev-9.6

	echo "$0: installed postgresql version: "
	pg_config --version 2>&1 
	echo "$0: expected output: PostgreSQL 9.6.1 or later"
	psql --version 2>&1 
	echo "$0: expected output: psql (PostgreSQL) 9.6.1 or later"

	echo "$0: chaning postgres config file ... "

	# 9.4, 9.5, 9.6 ... pick the latest
	PG_HBACONF=`ls -1 /etc/postgresql/*/main/pg_hba.conf|sort -n | tail -1`

	echo "$0: config file: ${PG_HBACONF}"
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

	echo "$0: NOT creating database .... "

	echo "$0: EITHER restore an existing database made with"
	echo "cd /; echo 'pg_dumpall | gzip -9 > /tmp/netflow.dmp.sql.gz' | su postgres "
	echo "using "
	echo "cd /; gunzip netflow.dmp.sql.gz"
	echo "echo 'psql -d postgres -f /tmp/netflow.dmp.sql' |  su postgres"
	echo "$0: OR"
	echo "$0: execute commands from below: (should be in /root/files/data/db"
	cat << EOF 
	echo 'psql -f db/1_create_netwlow_db.sql'             | su postgres	
	echo 'psql -f db/2_create_netflow_schema.sql'         | su postgres
	echo 'psql netflow -f db/netflow_flow.icmp_codes.sql' | su postgres
	echo 'psql netflow -f db/netflow_flow.icmp_types.sql' | su postgres
	echo 'psql netflow -f db/netflow_flow.protocols.sql'  | su postgres
	echo 'psql netflow -f db/netflow_flow.services.sql'   | su postgres

	echo "$0: connect with "
	echo "$0: ssh -v -L 5432:127.0.0.1:5432 sysadm@ddps-dev"

EOF
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

	install_build_essential
	
	add_developers

	change_sshd_config

	make_sftp_user

	install_postgresql

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

