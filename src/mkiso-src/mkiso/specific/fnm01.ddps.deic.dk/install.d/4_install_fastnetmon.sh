#!/bin/bash
#
#--------------------------------------------------------------------------------------#
# The script assuues "3_install-igb-ixgbe-and-rc.local.sh" has been executed and both
# /etc/rc.local and igx or ige drivers has been activated / installed
# The script installs fastnetmon as a package on Debian 9.1 and installs a default
# configuration files:
#  - /etc/fastnetmon.conf
#  - /etc/networks_list
#  - /etc/networks_whitelist
#--------------------------------------------------------------------------------------#

function install_fastmon_package()
{
	echo 'deb http://ftp.de.debian.org/debian sid main' > /etc/apt/sources.list.d/fastnetmon.list

	export DEBIAN_FRONTEND=noninteractive
	apt-get -y update; apt-get -y upgrade; apt-get -y dist-upgrade
	apt-get -y install fastnetmon
}

function make_config_files()
{	
	TMPL="/root/files/data/fastnetmon.conf_tmpl"
	CONF="/tmp/fastnetmon.conf"
	NW="/etc/networks_list"
	NWW="/etc/networks_whitelist"

	LIST_OF_LISTEN_INTERFACES=`find_listening_interface`
	sed "s/__LIST_OF_LISTEN_INTERFACES__/${LIST_OF_LISTEN_INTERFACES}/g" < ${TMPL} > ${CONF}
	diff ${CONF} ${TMPL}

}

function find_listening_interface()
{
	# should be in /etc/rc.local
	RC_LOCAL_IFNAME=`sed '/^IFNAME=/!d; s/^.*=//' /etc/rc.local`
	
	# better check anyway
	MAX_SPEED=""
	MAX_SPEED_IFNAMES=""

	for SPEED in "1Gbit/s" "10Gbit/s"
	do
		IFNAMES=`lshw -C network 2>/dev/null | egrep 'capacity:|logical name:' | sed 's/.*://' | while read string
		do
			line="$line $string"
			case $string in
				"$SPEED")	echo $INTERFACE
				;;
				*"bit/s")	INTERFACE=""
				;;
				*)	INTERFACE=$string
				;;
			esac
		done`
		IFNAMES="`echo $IFNAMES`"

		NUMBERS_FOUND=`echo $IFNAMES | wc -w |tr -d ' '`
		case $NUMBERS_FOUND in 
			0)	:
			;;
			*)	case $MAX_SPEED in
				"") MAX_SPEED="$SPEED"
					MAX_SPEED_IFNAMES="$IFNAMES"
				;;
				*)	:
				esac
			;;
		esac
	done

	echo "$RC_LOCAL_IFNAME"
}

function main()
{
	install_fastmon_package

	make_config_files


}

################################################################################
# main
################################################################################

main $*

exit 0

# Markdown documentation:
# sed '/^#:/!d; s/^#://' $0
