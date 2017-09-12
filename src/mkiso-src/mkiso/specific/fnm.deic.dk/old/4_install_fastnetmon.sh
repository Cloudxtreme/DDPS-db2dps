#!/bin/bash
#
# $Header$
#
#--------------------------------------------------------------------------------------#
# TODO
# - not sure if this is the right procedure - it will produce a new version of fnm
#   each time there is a change some where on git
#
#--------------------------------------------------------------------------------------#

DEVDIR=/root/files/data/developent/compile_fastnetmon

if [ ! -d "$DEVDIR" ]; then
	mkdir $DEVDIR
fi

cd $DEVDIR

wget -N https://raw.githubusercontent.com/pavel-odintsov/fastnetmon/master/src/fastnetmon_install.pl -Ofastnetmon_install.pl.ORG

apt-get -y install liblog4cpp5-dev

sed '
	s/$we_have_pfring_support = 1;/$we_have_pfring_support = 0/
	s/get_user_email..;//;
	s/send_tracking_information..started..;//;
	s/send_tracking_information..finished..;//;' fastnetmon_install.pl.ORG > fastnetmon_install.pl

chmod 755 fastnetmon_install.pl 

diff fastnetmon_install.pl.ORG fastnetmon_install.pl

./fastnetmon_install.pl  --use-git-master —-do-not-track-me


test -f /etc/sysctl.conf.org || {
	cp /etc/sysctl.conf /etc/sysctl.conf.org
}

# skal i script der også laver rc.local
INTERFACE=enp0s9

(
cat /etc/sysctl.conf.org
cat << EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.enp0s9.disable_ipv6 = 1
EOF
) > /etc/sysctl.conf

sysctl -p

#
# Statifier required
#
# cd /usr/local/src
# wget https://sourceforge.net/projects/statifier/files/latest/download?source=files -Ostatifier-1.7.4.tar.gz
# apt-get -y install g++-multilib
# tar xvfpz statifier-1.7.4.tar.gz
# cd /usr/local/statifier-1.7.4
# make all install

# statifier /opt/fastnetmon/fastnetmon /tmp/fastnetmon
# /bin/mv /opt/fastnetmon/fastnetmon /opt/fastnetmon/fastnetmon.dyn
# /bin/mv /tmp/fastnetmon /opt/fastnetmon/fastnetmon

# the static linked version runs while the client creates a core dump
# but the client does not use external non-standard libraries

systemctl enable fastnetmon.service
systemctl start fastnetmon.service


# installation new hosts once build:

# copy /etc/init.d/fastnetmon /opt/fastnetmon to .../data/precompiled_fastnetmon/
# copy 


