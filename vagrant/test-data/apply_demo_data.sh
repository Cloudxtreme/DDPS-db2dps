#! /usr/bin/env bash
#
# Install example/test data
#

RESTORE_SRC_DIR=/vagrant/test-data
export PATH=$PATH:/opt/db2dps/bin:/opt/mkiso/bin:/opt/pgpool2/bin
    
function print_vars()
{
    cat << EOF
Added postgress etc. configuration with the following parameters:
-----------------------------------------------------------------
dbusers:                      $dbusers
dbpass:                       $dbpass
dbname:                       $dbname
ipv4addr:                     $ipv4addr
ipv4listenaddress:            $ipv4listenaddress
pcp_listen_addresses:         $pcp_listen_addresses
backend_hostname0:            $backend_hostname0
backend_hostname1:            $backend_hostname1
sr_check_password:            ${sr_check_password}
sr_check_database:            ${sr_check_database}

default_uuid_administratorid: $default_uuid_administratorid
bootstrap_ip:                 $bootstrap_ip

dbusr:                        $dbusr
dbpassword:                   $dbpass
dbname:                       $dbname

ournetworks:                  $ournetworks

customerid                    $customerid
fastnetmoninstanceid          $fastnetmoninstanceid
uuid                          ddpsrules-cli-adm
administratorid               $administratorid

EOF

    echo "Installed the following system users with sudo privilegies:"
    echo "------------------------------------------------------------------------------------------------------------------------------------"
    echo " username  | userid   | name                            | public ssh key"
    echo "-----------+----------+---------------------------------+---------------------------------------------------------------------------"
    awk -F';' '{ printf(" %-9s | %8d | %-31s | %-.70s... \n", $1, $3, $2, $4) } ' < unix_users.csv

    echo ""
    echo "Postgres users:"
    echo "------------------------------------------------------------------------------------------------------------------------------------"
    echo 'select * from pg_shadow;' |sudo su postgres -c "cd /tmp; psql -d netflow" | sed '/^(.*rows)$/d'

}

function stop_services()
{
    service db2dps stop
    service db2fnm stop
    service exabgp stop
}

function start_services()
{
    # (re-)start services
    service exabgp start
    service db2dps start
    service db2fnm start
    systemctl is-active --quiet db2dps && echo Service db2dps is running
    systemctl is-active --quiet db2fnm && echo Service db2fnm is running
}
    
function create_example_database()
{
    # add data and schema to database
    echo "create example database .... "

    envsubst < $RESTORE_SRC_DIR/pgpool2/etc/pool_hba.conf.SH > /opt/pgpool2/etc/pool_hba.conf
    envsubst < $RESTORE_SRC_DIR/pgpool2/etc/pgpool.conf.SH   > /opt/pgpool2/etc/pgpool.conf

    gunzip -c test-data.sql.gz | sed "s/__PASSWORD__/${dbpass}/g" > /tmp/test-data.sql
    chown postgres /tmp/test-data.sql

    echo 'psql -d postgres -f /tmp/test-data.sql' | su postgres
    /bin/rm -f /tmp/test-data.sql

    for dbuser in ${dbusers}
    do
	if ! type pg_md5 >/dev/null; then 
        	/opt/pgpool2/bin/pg_md5 --md5auth --username=${dbuser} ${dbpass}
	else
        	pg_md5 --md5auth --username=${dbuser} ${dbpass}
	fi
    done

}

function apply_config_to_opt_db2dps()
{
    # /opt/db2dps/etc
    # test -f /opt/db2dps/etc/db.ini     || /bin/cp $RESTORE_SRC_DIR/opt_db2dps_etc/db.ini /opt/db2dps/etc
    # test -f /opt/db2dps/etc/fnmcfg.ini || /bin/cp $RESTORE_SRC_DIR/opt_db2dps_etc/fnmcfg.ini /opt/db2dps/etc

    envsubst < $RESTORE_SRC_DIR/opt_db2dps_etc/db.ini.SH     > /opt/db2dps/etc/db.ini
    envsubst < $RESTORE_SRC_DIR/opt_db2dps_etc/fnmcfg.ini.SH > /opt/db2dps/etc/fnmcfg.ini

    test -f /opt/db2dps/etc/ssh/id_rsa || ssh-keygen -t rsa -b 4096 -f  /opt/db2dps/etc/ssh/id_rsa -N ""
    test -d /root/.ssh || mkdir /root/.ssh && chmod 700 /root/.ssh

    grep -q "`cat /opt/db2dps/etc/ssh/id_rsa.pub`" /root/.ssh/authorized_keys || cat /opt/db2dps/etc/ssh/id_rsa.pub >> /root/.ssh/authorized_keys

    # make known_hosts
    HOSTLIST=`sed '/^hostlist/!d; s/.*=//; s/^[ \t]*//' /opt/db2dps/etc//db.ini`
    # assume same user
    for H in ${HOSTLIST}
    do
        RES=`echo "whoami" | ssh -qt -o ConnectTimeout=5 -o StrictHostKeyChecking=no $H -i /opt/db2dps/etc/ssh/id_rsa 2>/dev/null`
        case $RES in
            "root")   :
                ;;
            *)      echo "ssh $H failed:"
                    echo "whoami" | ssh -qt -o ConnectTimeout=5 -o StrictHostKeyChecking=no $H -i /opt/db2dps/etc/ssh/id_rsa 
            ;;
        esac
    done
}

function add_developers()
{
    echo "$0: adding developers from unix_users.csv: no password login admin rights ... "

    if [ -f ${RESTORE_SRC_DIR}/unix_users.csv ]; then
        OIFS=$IFS
        IFS=";"
        cat ${RESTORE_SRC_DIR}/unix_users.csv | while read USR GCOS ID KEY
        do
            getent passwd ${USR} >/dev/null 2>&1 >/dev/null || adduser --uid ${ID} --home /home/${USR} --shell /bin/bash --gecos "${GCOS}" --ingroup staff --disabled-password ${USR}
            usermod -a -G sudo  ${USR}
            sudo chage -d 0     ${USR}
            mkdir -p /home/${USR}/.ssh
            echo "$KEY" > /home/${USR}/.ssh/authorized_keys
            chown -R ${USR} /home/${USR}/.ssh/
            chmod 700 /home/${USR}/.ssh /home/${USR}/.ssh/*
            echo "added ${USR} ... "
        done
    else
        echo "0 developers added. Add dev.lst with the following syntax:"
        echo "\"username\" \"full name\" \"numeric user id\" "
    fi
    IFS=$OIFS
}

function generate_dk_locale()
{
    grep ^da_DK /etc/locale.gen >/dev/null  || {
        echo "$0: installing locale da_DK.UTF-8 .... "
        locale-gen en_DK.utf8
        locale-gen da_DK.UTF-8
}

function add_group_and_user()
{
    echo "installing ddpsadm user .... "
    getent passwd ddpsadm > /dev/null 2>&1  >/dev/null || adduser --home /home/ddpsadm --shell /bin/bash --gecos "DDPS admin" --ingroup staff --disabled-password ddpsadm

    echo "adding sftpgroup .... "
    if grep -q sftpgroup /etc/group
    then
         :
    else
        addgroup --system sftpgroup
    fi

    if [ -f /home/sftpgroup/newrules/.ssh/authorized_keys ]; then
        chattr -i /home/sftpgroup/newrules/.ssh/authorized_keys /home/sftpgroup/newrules/.ssh/  >/dev/null 2>&1
        rm -fr /home/sftpgroup/                                                                 >/dev/null 2>&1
        userdel -r newrules                                                                     >/dev/null 2>&1
        echo "removed existing user newrules"
    fi

    mkdir /home/sftpgroup; chown root:root /home/sftpgroup

    echo "setting up sftp user for fastnetmon .... "
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

    echo "permissions for /home/sftpgroup has been set carefully, dont change"
    echo "use chattr to lock / unlock /home/sftpgroup/newrules/.ssh/authorized_keys"

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

    echo "dummy key added to /home/sftpgroup/.ssh/authorized_keys"

    echo "Append /opt/db2dps/bin and /opt/mkiso/bin to PATH ... "
    echo "PATH=\$PATH:/opt/db2dps/bin:/opt/mkiso/bin" > /etc/profile.d/ddps.sh 
    chmod 644 /etc/profile.d/ddps.sh
    chown root:root /etc/profile.d/ddps.sh
}

function modify_sudoers()
{
    echo "$0: setting sudo without password ... "
    echo '%sudo ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/sudogrp
    chmod 0440 /etc/sudoers.d/sudogrp

    echo "$0: modify /etc/sudoers so /opt/db2dps/bin and /opt/mkiso/bin is in PATH "
    sed 's%.*secure_path.*%Defaults secure_path="/bin:/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/opt/db2dps/bin:/opt/mkiso/bin:/opt/pgpool2/bin"%' /etc/sudoers > /tmp/sudoers
    /bin/mv /tmp/sudoers /etc/sudoers
    chmod  0440 /etc/sudoers 
    chown root:root /etc/sudoers
}


function modify_sshd_config()
{
    # root has no pw, enable ssh login
    echo "enabling password less ssh root login ... "   
    echo "disabling password ssh login ... "
    echo "adding sftp group ... "
    usermod -p '*' root

    test -f /etc/ssh/sshd_config.org || {
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.org
    }

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

function apply_pgpool_configuration()
{
    echo 'create extension pgpool_recovery ; select * from pg_extension ;' | sudo su - postgres -c "cd /tmp; psql -d netflow -U postgres -p 5432"
}

function apply_exabgp_config()
{
    envsubst < $RESTORE_SRC_DIR/exabgp/exabgp.conf.SH > /etc/exabgp/exabgp.conf
    cp $RESTORE_SRC_DIR/exabgp/exabgp.env               /etc/exabgp/
    cp $RESTORE_SRC_DIR/exabgp/runsocat.sh              /etc/exabgp/
}

# nginx

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
        v)  VERBOSE=TRUE
        ;;
        *)  echo "usage: $0 [-v]"
            exit
        ;;
    esac
    done
    shift `expr $OPTIND - 1`

    . vars.SH

    stop_services
    generate_dk_locale
    add_developers
    add_group_and_user
    modify_sudoers 
    modify_sshd_config 
    create_example_database
    apply_pgpool_configuration
    apply_config_to_opt_db2dps
    apply_exabgp_config

    start_services

    print_vars

    exit 0
}


################################################################################
#
################################################################################

main $*

exit 0

# TODO
#  - exabgp
#  - nginx
#  - pgpool
