#!/bin/sh
#
# $Header$
# re-write in perl
#

#
# Vars
#
MYDIR=/path/to/some/dir
MYNAME=`basename $0`
MY_LOGFILE=/var/log/somelogfile
VERBOSE=FALSE
TMPFILE=/tmp/${MYNAME}.tmp

#
# Functions
#
function logit() {
# purpose     : Timestamp output
# arguments   : Line og stream
# return value: None
# see also    :
	LOGIT_NOW="`date '+%H:%M:%S (%d/%m)'`"
	STRING="$*"

	if [ -n "${STRING}" ]; then
		$echo "${LOGIT_NOW} ${STRING}" >> ${MY_LOGFILE}
		if [ "${VERBOSE}" = "TRUE" ]; then
			$echo "${LOGIT_NOW} ${STRING}"
		fi
	else
		while read LINE
		do
			if [ -n "${LINE}" ]; then
				$echo "${LOGIT_NOW} ${LINE}" >> ${MY_LOGFILE}
				if [ "${VERBOSE}" = "TRUE" ]; then
					$echo "${LOGIT_NOW} ${LINE}"
				fi
			else
				$echo "" >> ${MY_LOGFILE}
			fi
		done
	fi
}

function usage() {
# purpose     : Script usage
# arguments   : none
# return value: none
# see also    :
echo $*
cat << EOF

	Usage: `basename $0` options ...
	
	add new host, read options from database or write default vars to local filesystem:
		<-d|-l> -a hostname.tld

	update database with host information from filesystem
		-d  -u hostname.tld

	update local filesystem with info from database
		-l  -u hostname.tld

	See man pages for more info.
EOF
	exit 2
}

clean_f () {
# purpose     : Clean-up on trapping (signal)
# arguments   : None
# return value: None
# see also    :
	$echo trapped
	/bin/rm -f $TMPFILE $MAILFILE
}

function add_ssh_keys()
{
	chattr -i /home/sftpgroup/newrules/.ssh/authorized_keys /home/sftpgroup/newrules/.ssh/
	chattr +i /home/sftpgroup/newrules/.ssh   /home/sftpgroup/newrules/.ssh/*
}

function main()
{
	echo=/bin/echo
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
	while getopts a:dlu: opt
	do
	case $opt in
		a)	NEWHOST=$OPTARG
		;;
		d)	READ_FROM_DB=1
		;;
		l)	READ_FROM_FILES=1
		;;
		u)	UPDATEHOST=$OPTARG
		;;
		*)	usage
			exit
		;;
	esac
	done
	shift `expr $OPTIND - 1`

#	test -n "$NEWHOST"		|| usage "Error: no new host !"
#	test -n "$UPDATEHOST"	|| usage "Error: no host to update !"

	echo done

	exit 0
}

#
# clean up on trap(s)
#
trap clean_f 1 2 3 13 15

################################################################################
# Main
################################################################################

main $*

exit 0

#
# Documentation and  standard disclaimar
#
# Copyright (C) 2001 Niels Thomas Haugård
# UNI-C
# http://www.uni-c.dk/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the 
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#



-- object: flow.fastnetmoninstances | type: TABLE --
-- DROP TABLE IF EXISTS flow.fastnetmoninstances CASCADE;
CREATE TABLE flow.fastnetmoninstances(
	fastnetmon_instanceid bigint NOT NULL DEFAULT nextval('flow.fastnetmon_instances_fastnetmon_instanceid_seq'::regclass),
	customerid integer,
	mode character varying(7),
	internet_if text,
	lan_if text,
	fastnetmon_if text,
	gw text,
	vpn_ip_addr cidr,
	hostname text,
	key text,
	ovpn text,
	p12 text,
	usr text,
	password text,
	fastnetmoninstanceid integer,
	uuid text,
	administratorid integer,
	blocktime integer NOT NULL DEFAULT 10,
	public_ssh_key_for_upload_to_ddps text,
	private_ssh_key_for_upload_to_ddps text,
	networks_whitelist text,
	fastnetmonversion text,
	local_syslog_logging character varying(3) NOT NULL DEFAULT 'off'::character varying,
	remote_syslog_logging character varying(3) NOT NULL DEFAULT 'off'::character varying,
	remote_syslog_server cidr,
	remote_syslog_port integer NOT NULL DEFAULT 514,
	enable_ban character varying(3) NOT NULL DEFAULT 'on'::character varying,
	process_incoming_traffic character varying(3) NOT NULL DEFAULT 'on'::character varying,
	process_outgoing_traffic character varying(3) NOT NULL DEFAULT 'off'::character varying,
	ban_details_records_count bigint NOT NULL DEFAULT 100,
	ban_time integer NOT NULL DEFAULT 10,
	unban_only_if_attack_finished character varying(3) NOT NULL DEFAULT 'off'::character varying,
	enable_subnet_counters character varying(3) NOT NULL DEFAULT 'on'::character varying,
	networks_list_path text NOT NULL DEFAULT '/etc/networks_list'::text,
	white_list_path text NOT NULL DEFAULT '/etc/networks_whitelist'::text,
	check_period integer NOT NULL DEFAULT 1,
	enable_connection_tracking character varying(3) NOT NULL DEFAULT 'on'::character varying,
	ban_for_pps character varying(3) NOT NULL DEFAULT 'on'::character varying,
	ban_for_bandwidth character varying(3) NOT NULL DEFAULT 'on'::character varying,
	ban_for_flows character varying(3) NOT NULL DEFAULT 'on'::character varying,
	threshold_pps bigint DEFAULT 20000,
	threshold_mbps bigint DEFAULT 1000,
	threshold_flows bigint DEFAULT 3500,
	threshold_tcp_mbps bigint DEFAULT 10000,
	threshold_udp_mbps bigint DEFAULT 10000,
	threshold_icmp_mbps bigint DEFAULT 10000,
	threshold_tcp_pps bigint DEFAULT 10000,
	threshold_udp_pps bigint DEFAULT 10000,
	threshold_icmp_pps bigint DEFAULT 10000,
	ban_for_tcp_bandwidth character varying(3) NOT NULL DEFAULT 'on'::character varying,
	ban_for_udp_bandwidth character varying(3) NOT NULL DEFAULT 'on'::character varying,
	ban_for_icmp_bandwidth character varying(3) NOT NULL DEFAULT 'on'::character varying,
	ban_for_tcp_pps character varying(3) NOT NULL DEFAULT 'on'::character varying,
	ban_for_udp_pps character varying(3) NOT NULL DEFAULT 'on'::character varying,
	ban_for_icmp_pps character varying(3) NOT NULL DEFAULT 'on'::character varying,
	mirror character varying(3) NOT NULL DEFAULT 'off'::character varying,
	pfring_sampling_ratio integer NOT NULL DEFAULT 1,
	mirror_netmap character varying(3) NOT NULL DEFAULT 'on'::character varying,
	mirror_snabbswitch character varying(3) NOT NULL DEFAULT 'off'::character varying,
	mirror_afpacket character varying(3) NOT NULL DEFAULT 'off'::character varying,
	netmap_sampling_ratio integer NOT NULL DEFAULT 1,
	netmap_read_packet_length_from_ip_header character varying(3) NOT NULL DEFAULT 'off'::character varying,
	pcap character varying(3) NOT NULL DEFAULT 'off'::character varying,
	netflow character varying(3) NOT NULL DEFAULT 'off'::character varying,
	sflow character varying(3) NOT NULL DEFAULT 'off'::character varying,
	enable_pf_ring_zc_mode character varying(3) NOT NULL DEFAULT 'off'::character varying,
	interfaces character varying(128) NOT NULL DEFAULT 'eth1'::character varying,
	average_calculation_time integer NOT NULL DEFAULT 5,
	average_calculation_time_for_subnets integer NOT NULL DEFAULT 20,
	netflow_port integer NOT NULL DEFAULT 2055,
	netflow_host cidr NOT NULL DEFAULT '0.0.0.0/0'::cidr,
	netflow_sampling_ratio integer NOT NULL DEFAULT 1,
	netflow_divide_counters_on_interval_length character varying(3) NOT NULL DEFAULT 'off'::character varying,
	netflow_lua_hooks_path text NOT NULL DEFAULT '/usr/src/fastnetmon/src/netflow_hooks.lua'::text,
	sflow_port integer NOT NULL DEFAULT 6343,
	sflow_host cidr NOT NULL DEFAULT '0.0.0.0/0'::cidr,
	notify_script_path text NOT NULL DEFAULT 'opt/i2dps/bin/fnm2db'::text,
	notify_script_pass_details character varying(3) NOT NULL DEFAULT 'on'::character varying,
	collect_attack_pcap_dumps character varying(3) NOT NULL DEFAULT 'off'::character varying,
	process_pcap_attack_dumps_with_dpi character varying(3) NOT NULL DEFAULT 'off'::character varying,
	redis_enabled character varying(3) NOT NULL DEFAULT 'off'::character varying,
	redis_port integer NOT NULL DEFAULT 6379,
	redis_host cidr NOT NULL DEFAULT '127.0.0.1/32'::cidr,
	redis_prefix character varying(255) NOT NULL DEFAULT 'mydc1'::character varying,
	mongodb_enabled character varying(3) NOT NULL DEFAULT 'off'::character varying,
	mongodb_host character varying(128) NOT NULL DEFAULT 'localhost'::character varying,
	mongodb_port integer NOT NULL DEFAULT 27017,
	mongodb_database_name character varying(128) NOT NULL DEFAULT 'fastnetmon'::character varying,
	pfring_hardware_filters_enabled character varying(3) NOT NULL DEFAULT 'off'::character varying,
	exabgp character varying(3) NOT NULL DEFAULT 'off'::character varying,
	exabgp_command_pipe character varying(255) NOT NULL DEFAULT '/var/run/exabgp.cmd'::character varying,
	exabgp_community text,
	exabgp_community_subnet text,
	exabgp_community_host text,
	exabgp_next_hop cidr NOT NULL DEFAULT '10.0.3.114/32'::cidr,
	exabgp_announce_host character varying(3) NOT NULL DEFAULT 'on'::character varying,
	exabgp_announce_whole_subnet character varying(3) NOT NULL DEFAULT 'off'::character varying,
	exabgp_flow_spec_announces character varying(3) NOT NULL DEFAULT 'off'::character varying,
	gobgp character varying(3) NOT NULL DEFAULT 'off'::character varying,
	gobgp_next_hop cidr NOT NULL DEFAULT '0.0.0.0/0'::cidr,
	gobgp_announce_host character varying(3) NOT NULL DEFAULT 'on'::character varying,
	gobgp_announce_whole_subnet character varying(3) NOT NULL DEFAULT 'off'::character varying,
	graphite character varying(3) NOT NULL DEFAULT 'on'::character varying,
	graphite_host cidr NOT NULL DEFAULT '127.0.0.1/32'::cidr,
	graphite_port integer NOT NULL DEFAULT 2003,
	graphite_prefix character varying(255) NOT NULL DEFAULT 'fastnetmon'::character varying,
	monitor_local_ip_addresses character varying(3) NOT NULL DEFAULT 'off'::character varying,
	hostgroup text NOT NULL DEFAULT 'my_hosts:10.10.10.221/32,10.10.10.222/32'::text,
	my_hosts_enable_ban character varying(3) NOT NULL DEFAULT 'off'::character varying,
	my_hosts_ban_for_pps character varying(3) NOT NULL DEFAULT 'off'::character varying,
	my_hosts_ban_for_bandwidth character varying(3) NOT NULL DEFAULT 'off'::character varying,
	my_hosts_ban_for_flows character varying(3) NOT NULL DEFAULT 'off'::character varying,
	my_hosts_threshold_pps integer NOT NULL DEFAULT 20000,
	my_hosts_threshold_mbps integer NOT NULL DEFAULT 1000,
	my_hosts_threshold_flows integer NOT NULL DEFAULT 3500,
	pid_path character varying(255) NOT NULL DEFAULT '/var/run/fastnetmon.pid'::character varying,
	cli_stats_file_path character varying(255) NOT NULL DEFAULT '/tmp/fastnetmon.dat'::character varying,
	enable_api character varying(3) NOT NULL DEFAULT 'off'::character varying,
	sort_parameter character varying(128) NOT NULL DEFAULT 'packets'::character varying,
	max_ips_in_list integer NOT NULL DEFAULT 7,
	networks_list text,

);
-- ddl-end --
ALTER TABLE flow.fastnetmoninstances OWNER TO flowuser;
-- ddl-end --
