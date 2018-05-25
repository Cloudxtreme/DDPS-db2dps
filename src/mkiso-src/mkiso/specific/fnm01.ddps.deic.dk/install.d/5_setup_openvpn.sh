#!/bin/sh
#
# This is for OpenBSD
# Keys are stored as e.g.  test01.fnm.ddps.deic.dk.ovpn but must be renamed
# to openvpn.conf on Debian
#

# OpenVPN configuration provided by ddps server
OPENVPN_CFG=/root/files/data/openvpn

# OpenVPN defaults
DEFAULTS=/etc/default/openvpn

if [ ! -f ${DEFAULTS}.org ]; then
	/bin/cp ${DEFAULTS} ${DEFAULTS}.org
fi

# Enable all configs
sed 's/^#AUTOSTART="all"/AUTOSTART="all"/' ${DEFAULTS}.org > ${DEFAULTS}
chmod 0644 ${DEFAULTS}
chown root:root ${DEFAULTS}

cd ${OPENVPN_CFG}

# Remove any existing *conf *.key and *.p12 from /etc/openvpn
/bin/rm -f /etc/openvpn/*.conf /etc/openvpn/*.key /etc/openvpn/*.p12

/bin/cp *.ovpn /etc/openvpn/
(
    cd /etc/openvpn
    ln -fs *.ovpn openvpn.conf
)

service openvpn stop
systemctl enable openvpn
service openvpn start

# __DATA__
#
## Config is stored in a zip archive from pfsense
#
#unzip -nj *.zip
#
#CERT=`echo *.p12`
#KEY=`echo *.key`
#CFG=`echo *.ovpn`
#PW="pass.txt"
#
## The config file *must* have suffix `.conf` not `.ovpn`
#mv $CFG  `basename -s .ovpn openvpn.conf`
#CFG=`echo *.conf`
#
## Add password file info to CFG
#if [ ! -f ${CFG}.org ]; then
#	/bin/cp ${CFG} ${CFG}.org
#fi
#
#(
#	sed '/auth-user-pass/d;' < ${CFG}.org
#	cat <<-EOF
#	# use credentials from file
#	auth-user-pass pass.txt
#	# This updates the resolvconf with dns settings
#	setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#	script-security 2
#	up /etc/openvpn/update-resolv-conf
#	down /etc/openvpn/update-resolv-conf
#	down-pre
#EOF
#
#) > ${CFG}
#chmod 0644 ${CFG}
#chown root:root ${CFG}
#
#cat << EOF
#CERT: `file $CERT`
#KEY:  `file $CERT`
#CFG:  `file $CFG`
#PW:   `file $PW`
#EOF
#
