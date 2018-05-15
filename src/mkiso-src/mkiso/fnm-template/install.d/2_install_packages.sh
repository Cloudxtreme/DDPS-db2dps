#!/bin/sh

# General debug and vpn tools
export DEBIAN_FRONTEND=noninteractive
apt-get -y install vim tcpdump ethtool tmux openvpn unzip rsync lshw
apt-get -y install locales-all

locale-gen en_DK.utf8

# Required tools for fastnetmon (install_fastnetmon.pl)
#apt-get install -y	git autoconf automake cmake g++ gcc git libboost-all-dev	\
#					libgeoip-dev libgpm-dev libhiredis-dev	liblog4cpp5-dev		\
#					libncurses5-dev libnuma-dev libpcap-dev libtool pkg-config

