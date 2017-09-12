:

# cat  /etc/apt/sources.list | grep -v 'deb http://ftp.de.debian.org/debian sid main'

echo 'deb http://ftp.de.debian.org/debian sid main' > /etc/apt/sources.list.d/fastnetmon.list

apt-get -y update; apt-get -y upgrade; apt-get -y dist-upgrade

apt-get -y install fastnetmon
