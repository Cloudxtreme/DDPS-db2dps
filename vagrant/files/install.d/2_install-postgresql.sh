#!/bin/bash
#
# DeIC DPS: development database server installation 
#
# Pre-requisite for the development environment:
# virtualbox or similar
# Ubuntu server 16.04 with an sshd server, no automatic update
# preferably two net cards, one with internet access for updates etc.
# and one for (static) connecting from the development environment

DATADIR=../data/
TMPFILE=`tempfile`
MYNAME=`basename $0`

# functions

function savefile()
{
	if [ ! -f "$1" ]; then
		echo "$MYNAME: program error in function savefile, file '$1' not found"
		exit 0
	fi
	if [ ! -f "$1".org ]; then
		echo "$MYNAME: function savefile: saving original $1 as $1.org ... "
		cp "$1" "$1".org
	fi
}

function make_sftp_user()
{
	echo "$MYNAME: adduser 'ddpsadm' .... "
	getent passwd ddpsadm > /dev/null 2>&1  >/dev/null || adduser --home /home/ddpsadm --shell /bin/bash --gecos "DDPS admin" --ingroup staff --disabled-password ddpsadm

	echo "$MYNAME: adding 'sftpgroup' .... "
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
		echo "$MYNAME: removed existing user newrules"
	fi

    echo "$MYNAME: creating /home/sftpgroup; chown root:root /home/sftpgroup ... "
	mkdir /home/sftpgroup; chown root:root /home/sftpgroup

	echo "$MYNAME: adduser 'newrules' sftp user for fastnetmon upload .... "
	getent passwd newrules >/dev/null 2>&1 >/dev/null || useradd -m -c "DDPS rules upload" -d /home/sftpgroup/newrules/ -s /sbin/nologin newrules
	usermod -G sftpgroup newrules
    usermod -p '*'       newrules

	chmod 755          /home/sftpgroup /home/sftpgroup/newrules/
	mkdir -p           /home/sftpgroup/newrules/.ssh
	chmod 700          /home/sftpgroup/newrules/.ssh
	chown -R root:root /home/sftpgroup /home/sftpgroup/newrules/

	test -d /home/sftpgroup/newrules/upload || mkdir /home/sftpgroup/newrules/upload
	chown newrules:newrules /home/sftpgroup/newrules/upload
	chmod 777 /home/sftpgroup/newrules/upload

	echo "$MYNAME: permissions for /home/sftpgroup has been set carefully, dont change"
	echo "$MYNAME: use chattr to lock / unlock /home/sftpgroup/newrules/.ssh/authorized_keys"

	chattr -i /home/sftpgroup/newrules/.ssh/
	if [ -f /home/sftpgroup/newrules/.ssh/authorized_keys ]; then
		chattr -i /home/sftpgroup/newrules/.ssh/authorized_keys
	fi
	# this is a dummy key
	cat << EOF | tr -d '\n' > /home/sftpgroup/newrules/.ssh/authorized_keys
ssh-ed25519 AAAAC3NIamAdummyKeyJustToSeIfaScriptWorksAsExprecredXXXXXXXXXXXXXXXX root@00:25:90:46:c2:fe-fastnetmon2.deic.dk
EOF
	chown -R newrules:newrules /home/sftpgroup/newrules/.ssh
	chattr +i /home/sftpgroup/newrules/.ssh   /home/sftpgroup/newrules/.ssh/*

	echo "$MYNAME: dummy key added to /home/sftpgroup/.ssh/authorized_keys"
}

function install_postgresql()
{
	# see https://www.postgresql.org/about/news/1432/
	echo "$MYNAME: installing postgresql ... "

	echo "$MYNAME: adding PPA to /etc/apt/sources.list.d/pgdg.list ... "
	echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" > /etc/apt/sources.list.d/pgdg.list

	cat << EOF > /etc/apt/preferences.d/pgdg.pref
Package: *
Pin: release o=apt.postgresql.org
Pin-Priority: 500
EOF

echo "$MYNAME: apt-key add ACCC4CF8 (www.postgresql.org)  ... apt-get update with new PPA ..."
	wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
	apt-get -y update >$TMPFILE
    case $? in
        0)  echo "$MYNAME: done"
            ;;
        *)  echo "$MYNAME: failed:"
            cat $TMPFILE
    esac

    echo "installing postgresql-9.6 and related packages ... "
    apt-get -y install postgresql-9.6 postgresql-client-9.6 postgresql-client-common postgresql-common postgresql-contrib-9.6 postgresql-server-dev-9.6 sysstat libsensors4 libpq-dev > $TMPFILE
    case $? in
        0)  echo "$MYNAME: done"
            ;;
        *)  echo "$MYNAME: failed:"
            cat $TMPFILE
            ;;
    esac

    echo "setting apt-mark hold as pgpool2 does not work with the latest postgres ... (KASM)"
    # Sæt pakkerne på hold:
    apt-mark hold postgresql-9.6 postgresql-client-9.6 postgresql-client-common postgresql-common postgresql-contrib-9.6 postgresql-server-dev-9.6

	echo "$MYNAME: installed postgresql version: "
	pg_config --version 2>&1 
	echo "$MYNAME: expected output: PostgreSQL 9.6.1 or later"
	psql --version 2>&1 
	echo "$MYNAME: expected output: psql (PostgreSQL) 9.6.1 or later"

	echo "$MYNAME: chaning postgres config file ... "

	# 9.4, 9.5, 9.6 ... pick the latest
	PG_HBACONF=`ls -1 /etc/postgresql/*/main/pg_hba.conf|sort -n | tail -1`

	echo "$MYNAME: config file: ${PG_HBACONF}"
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
    echo "postgresql installed and started, changes to ${PG_HBACONF}:"
    diff ${PG_HBACONF} ${PG_HBACONF}.org 

    echo "$MYNAME: database NOT created"

#	echo "$0: NOT creating database .... "
#
#	echo "$0: EITHER restore an existing database made with"
#	echo "cd /; echo 'pg_dumpall | gzip -9 > /tmp/netflow.dmp.sql.gz' | su postgres "
#	echo "using "
#	echo "cd /; gunzip netflow.dmp.sql.gz"
#	echo "echo 'psql -d postgres -f /tmp/netflow.dmp.sql' |  su postgres"
#	echo "$0: OR"
#	echo "$0: execute commands from below: (should be in /root/files/data/db"
#	cat << EOF 
#	echo 'psql -f db/1_create_netwlow_db.sql'             | su postgres	
#	echo 'psql -f db/2_create_netflow_schema.sql'         | su postgres
#	echo 'psql netflow -f db/netflow_flow.icmp_codes.sql' | su postgres
#	echo 'psql netflow -f db/netflow_flow.icmp_types.sql' | su postgres
#	echo 'psql netflow -f db/netflow_flow.protocols.sql'  | su postgres
#	echo 'psql netflow -f db/netflow_flow.services.sql'   | su postgres
#
#	echo "$0: connect with "
#	echo "$0: ssh -v -L 5432:127.0.0.1:5432 sysadm@ddps-dev"
#
#EOF
}

function main()
{
	install_postgresql

    rm -f $TMPFILE

	exit 0

	USR_LIST=`sed '/nologin$/d; /false$/d; s/:.*//' /etc/passwd`
	USR_LIST=`echo $USR_LIST`

	echo "$0: ARNING: do not log out without adding your public ssh keys to .ssh/authorized_keys"
	echo "$0: for one of the users $USR_LIST"

}

################################################################################
# Main
################################################################################

main $*

