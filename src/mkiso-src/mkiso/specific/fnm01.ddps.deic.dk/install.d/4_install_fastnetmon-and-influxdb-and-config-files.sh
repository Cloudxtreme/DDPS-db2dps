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
	apt-get -y  autoremove

	#systemctl enable fastnetmon.service
	#systemctl start fastnetmon.service
}

function install_influxdb_package()
{
	apt-get update
	apt-get -y upgrade
	apt-get -y install apt-transport-https curl
	curl -sL https://repos.influxdata.com/influxdb.key				|	\
		apt-key add -
	echo "deb https://repos.influxdata.com/debian jessie stable"	|	\
		tee /etc/apt/sources.list.d/influxdb.list
	apt-get update
	apt-get -y install influxdb
	apt-get -y  autoremove
}

function make_config_files()
{	
	make_fastnetmon_configuration
	make_sysctl_configuration
	make_influxdb_configuration
}

function make_fastnetmon_configuration()
{	
	TMPL="/root/files/data/config_files/etc/fastnetmon.conf_tmpl"
	CONF="/etc/fastnetmon.conf"
	NW="/etc/networks_list"
	NWW="/etc/networks_whitelist"

	LIST_OF_LISTEN_INTERFACES=`find_listening_interface`
	sed "
		s/__LIST_OF_LISTEN_INTERFACES__/${LIST_OF_LISTEN_INTERFACES}/g
		" < ${TMPL} > ${CONF}
	echo "in ${CONF}: fastnetmon listen interface is ${LIST_OF_LISTEN_INTERFACES} identical to /etc/rc.local"
	echo "diff ${CONF} ${TMPL}:"
	diff ${CONF} ${TMPL}
	
	echo "re-using networks_list and networks_whitelist from /root/files/data/config_files/etc"
	cp /root/files/data/config_files/etc/networks_list			/etc
	cp /root/files/data/config_files/etc/networks_whitelist		/etc

	# to be updated from the UI/database
}

function make_sysctl_configuration()
{
	echo "disabeling IPv6 in sysctl for fastnetmon ... "
	test -f /etc/sysctl.conf.org || {
	cp /etc/sysctl.conf /etc/sysctl.conf.org
	}

	(
	cat /etc/sysctl.conf.org
	cat <<-EOF
	net.ipv6.conf.all.disable_ipv6 = 1
	net.ipv6.conf.default.disable_ipv6 = 1
	net.ipv6.conf.lo.disable_ipv6 = 1
	net.ipv6.conf.${LIST_OF_LISTEN_INTERFACES}.disable_ipv6 = 1
EOF
	) > /etc/sysctl.conf

	sysctl -p
}

function make_influxdb_configuration()
{
	echo "changing influxdb/influxdb.conf ..."
	test -f /etc/influxdb/influxdb.conf.org || {
		cp /etc/influxdb/influxdb.conf /etc/influxdb/influxdb.conf.org
		echo "preserved existing /etc/influxdb/influxdb.conf"
	}
	/bin/cp /root/files/data/config_files/etc/influxdb/influxdb.conf /etc/influxdb/influxdb.conf
	echo "installed new /etc/influxdb/influxdb.conf"
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

function test_everything()
{
	case `influx -execute 'SHOW DATABASES' |grep graphite` in
		"graphite")	echo "ok: graphite database found in influxdb"
		;;
		*)	echo "fail: graphite database not found in influxdb"
		return -1
		;;
	esac

	case `influx -database 'graphite' -execute 'SHOW TAG KEYS' -format 'column'|egrep 'app|direction|resource'|wc -l|tr -d ' '` in
		3)	echo "ok: found something in influxdb ... "
		;;
		*)	echo "fail: influxdb empty (no schema)"
		;;
	esac
}

function main()
{
	install_fastmon_package
	install_influxdb_package

	make_config_files

	service fastnetmon stop
	service influxdb stop
	service influxdb start
    service fastnetmon start

	test_everything
}

################################################################################
# main
################################################################################

main $*

exit 0

# Markdown documentation:
# sed '/^#:/!d; s/^#://' $0
