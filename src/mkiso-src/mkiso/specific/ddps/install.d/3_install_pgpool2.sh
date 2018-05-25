#! /bin/bash
#
# Install the latest version of pgpool2
#

echo "$0: installing pgpool2 from git ... "
apt -y install git autoconf bison byacc

cd /usr/local/src/
git clone https://github.com/pgpool/pgpool2.git

cd pgpool2/

touch configure.ac aclocal.m4 configure Makefile.am Makefile.in
autoreconf
./configure --prefix=/opt/pgpool2
automake
make install
make clean

# logit "Append /opt/db2dps/bin and /opt/mkiso/bin to PATH ... "
# Installed in non-default location, so add PATH 

echo 'PATH=$PATH:/opt/pgpool2/bin' > /etc/profile.d/pgpool2.sh
chmod 644 /etc/profile.d/pgpool2.sh
chown root:root /etc/profile.d/pgpool2.sh

echo 'd /var/run/pgpool/ 0755 postgres postgres - ' > /etc/tmpfiles.d/pgpool.conf

# cat << EOF > /opt/pgpool2/etc/pgpool.conf
# EOF

