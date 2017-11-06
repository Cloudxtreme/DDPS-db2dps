#!/bin/sh
#
# NTH
#
 
#:   1 Apply all patches by doing an update, upgrade and a dist-upgrade
apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade

#:   2 Install local packages cmod, dailybuandupdate and grouproot.
cd      /root/files
dpkg -i cmod_1.1-2.deb
dpkg -i dailybuandupdate_1.7-1.deb
dpkg -i grouproot_1.2-1.deb

#:   3 Set DK console keyboard, xenial preseed cannot set keyboard layout, as of
#:     Bug #1553147 reported by Schlomo Schapiro on 2016-03-04, this fixes it
sed 's/^XKBLAYOUT=.*/XKBLAYOUT="dk"/; s/^XKBVARIANT=.*/XKBVARIANT=""/' /etc/default/keyboard > /tmp/keyboard
/bin/mv /tmp/keyboard /etc/default/keyboard
chown root:root /etc/default/keyboard
chmod 0644 /etc/default/keyboard
setupcon -k -f --save

#:   4 Ubuntu timesyncd is fine for most purposes, but ntpd uses more
#:     sophisticated techniques to constantly and gradually keep the system time on
#:     track. So disable uses more sophisticated techniques to constantly and
#:     gradually keep the system time on track and install ntpd
timedatectl set-ntp no
apt-get -y install ntp

#:   5 Run each each script in install.d. This is where different hosts are being produced
cd install.d

find . -type f | while read SHELLSCRIPT
do
	bash ${SHELLSCRIPT}
done

echo "all done" > ./finished
logger -p mail.crig "Installation complete"

# etc - loads cut
sed -i 's_sh /root/files/install.sh_exit 0_' /etc/rc.local

# Re-boot is usually required after a dist-upgrade instead of checking just do it
/sbin/reboot
