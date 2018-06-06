#! /usr/bin/env bash
#
# Restore / install example / test data
#
# The database information is currently based on actual test-pre-production data, this should be changed
# Also, the pgpool2 data is not installed

# everything below here
RESTORE_SRC_DIR=/vagrant/restore-example-data

# stop services
service db2dps stop
service db2fnm stop

# add data and schema to database
echo "create example database .... "
cd /tmp
gunzip -c ${RESTORE_SRC_DIR}/dumpall-with-oids.gz > /tmp/restore
chown postgres /tmp/restore
echo 'psql -d postgres -f  /tmp/restore' | su postgres

# /opt/db2dps/etc
test -f /opt/db2dps/etc/db.ini || /bin/cp $RESTORE_SRC_DIR/db.ini /opt/db2dps/etc
test -f /opt/db2dps/etc/fnmcfg.ini || /bin/cp $RESTORE_SRC_DIR/fnmcfg.ini /opt/db2dps/etc

test -f /opt/db2dps/etc/ssh/id_rsa || ssh-keygen -t rsa -b 4096 -f  /opt/db2dps/etc/ssh/id_rsa -N ""
test -d /root/.ssh || mkdir /root/.ssh && chmod 700 /root/.ssh
grep -q "`cat /opt/db2dps/etc/ssh/id_rsa.pub`" /root/.ssh/authorized_keys || cat /opt/db2dps/etc/ssh/id_rsa.pub >> /root/.ssh/authorized_keys

# make known_hosts
HOSTLIST=`sed '/^hostlist/!d; s/.*=//; s/^[ \t]*//' $RESTORE_SRC_DIR/opt_db2dps_etc/db.ini`
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

echo "$0: adding developers from unix_users.csv: no password login admin rights ... "

if [ -f ${RESTORE_SRC_DIR}/unix_users.csv ]; then
    OIFS=$IFS
    IFS=";"
    cat ${RESTORE_SRC_DIR}/unix_users.csv | while read USR GCOS ID KEY
    do
        echo "$0: adding user ${USR} ... "
        getent passwd ${USR} >/dev/null 2>&1 >/dev/null || adduser --uid ${ID} --home /home/${USR} --shell /bin/bash --gecos "${GCOS}" --ingroup staff --disabled-password ${USR}
        usermod -a -G sudo	${USR}
        sudo chage -d 0		${USR}
        mkdir -p /home/${USR}/.ssh
        echo "$KEY" > /home/${USR}/.ssh/authorized_keys
        chown -R ${USR} /home/${USR}/.ssh/
        chmod 700 /home/${USR}/.ssh /home/${USR}/.ssh/*
    done
else
    echo "$0: 0 developers added. Add dev.lst with the following syntax:"
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

# root has no pw, enable ssh login
echo "$0: enabling password less ssh root login ... "	
usermod -p '*' root

test -f /etc/ssh/sshd_config.org || {
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.org
}

echo "$0: disabling password ssh login ... "
echo "$0: adding sftp group ... "
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
    chattr -i /home/sftpgroup/newrules/.ssh/authorized_keys /home/sftpgroup/newrules/.ssh/	>/dev/null 2>&1
    rm -fr /home/sftpgroup/																	>/dev/null 2>&1
    userdel -r newrules																		>/dev/null 2>&1
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

echo "dummy key added to /home/sftpgroup/.ssh/authorized_keys"

echo "Append /opt/db2dps/bin and /opt/mkiso/bin to PATH ... "
echo "PATH=\$PATH:/opt/db2dps/bin:/opt/mkiso/bin" > /etc/profile.d/ddps.sh 
chmod 644 /etc/profile.d/ddps.sh
chown root:root /etc/profile.d/ddps.sh

echo "$0: modify /etc/sudoers so /opt/db2dps/bin and /opt/mkiso/bin is in PATH "
sed 's%.*secure_path.*%Defaults	secure_path="/bin:/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/opt/db2dps/bin:/opt/mkiso/bin:/opt/pgpool2/bin"%' /etc/sudoers > /tmp/sudoers
/bin/mv /tmp/sudoers /etc/sudoers
chmod  0440 /etc/sudoers 
chown root:root /etc/sudoers

# root has no pw, enable ssh login
echo "enabling password less ssh root login ... "	
echo "disabling password ssh login ... "
echo "adding sftp group ... "
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

service db2dps start
service db2fnm start


service db2dps status
service db2fnm status


# exabgp

exit 0

├── pgpool2
│   ├── etc
│   │   ├── pgpool.conf
│   │   ├── pool_hba.conf
│   │   └── pool_passwd
│   └── etc_sample


