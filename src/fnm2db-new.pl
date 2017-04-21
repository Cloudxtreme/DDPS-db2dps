#!/usr/bin/perl -w
#
# $Header$
#
#++
# ## Pseudo code for fnm2db
#
# ``fnm2db`` is failsafe, and dies silently if args or input is invalid.
#
# ``fnm2db`` is triggered when a DDoS attack is detected by _fastnetmon_.
#
# ## Usage:
#
# ``fnm2db`` client_ip_as_string data_direction pps action
#
#      Rest is read from std-in.
#
# Pseudo code:
#
#```bash
#	if [ invalid argument OR argument is unban ]
#	{
#		exit
#	}
#	while read tcpdump from stdin
#	{
#		process some 47 parameters
#	}
#	read configuration file || fail
#	build sql statement
#	if [ connect to database and insert flowspec rules ]
#	{
#		exit OK
#	}
#	else
#	{
#		exit FAIL
# }
#```
#	``fnm2db`` is written in perl, and requires the following packages on Debian GNU/Linux 8:
#
#         sudo apt-get install libnet-openssh-compat-perl
#         apt-get install libnet-openssh-compat-perl
#         apt-get -y install libnet-ssh2-perl
#
#--

# prototypes
sub main(@);
sub logit(@);
sub mydie(@);
sub parse_ip($);
#sub parse_ip6($);
sub parse_v4(@);

#
# Requirements
#
use strict;
use warnings;
use sigtrap qw(die normal-signals);

use Sys::Syslog;		# only needed for logit
use POSIX;				# only needed for logit
use Net::SSH2;			# ssh v2 access to postgres db

#
# Global vars
#
my $usage = "\n$0	client_ip_as_string data_direction pps action\n";

# tcpdump
my ($date, $time, $src_sport, $andgt, $dst_dport, $protocol, $frag, $packets, $size, $str, $ttl, $ratio);
my ($src, $sport, $dst, $dport, $ver, $ip, $port);

# fastnetmon specific
my (
	$attack_type, $Initial_attack_power, $Peak_attack_power, $attack_protocol,
	$Total_incoming_traffic, $Attack_direction, $Total_outgoing_traffic,
	$Total_incoming_pps, $Total_outgoing_pps, $Total_incoming_flows,
	$Total_outgoing_flows, $Average_incoming_traffic, $Average_outgoing_traffic,
	$Average_incoming_pps, $Average_outgoing_pps, $Average_incoming_flows,
	$Average_outgoing_flows, $Incoming_ip_fragmented_traffic,
	$Outgoing_ip_fragmented_traffic, $Incoming_ip_fragmented_pps,
	$Outgoing_ip_fragmented_pps, $Incoming_tcp_traffic, $Outgoing_tcp_traffic,
	$Incoming_tcp_pps, $Outgoing_tcp_pps, $Incoming_syn_tcp_traffic,
	$Outgoing_syn_tcp_traffic, $Incoming_syn_tcp_pps, $Outgoing_syn_tcp_pps,
	$Incoming_udp_traffic, $Outgoing_udp_traffic, $Incoming_udp_pps,
	$Outgoing_udp_pps, $Incoming_icmp_traffic, $Outgoing_icmp_traffic,
	$Incoming_icmp_pps, $Outgoing_icmp_pps, $Network_incoming_traffic,
	$Network_outgoing_traffic, $Network_incoming_pps, $Network_outgoing_pps,
	$Average_network_incoming_traffic, $Average_network_outgoing_traffic,
	$Average_network_incoming_pps, $Average_network_outgoing_pps,
	$Average_packet_size_for_incoming_traffic,
	$Average_packet_size_for_outgoing_traffic
	);


my $verbose = 0;

my $logfile = "/opt/i2dps/tmp/" . "logfile.txt";
my $inicfg	= "/opt/i2dps/etc/fnm2db.ini";

# included from version.pm
# my $build_date = "2017-02-16 15:16";
# my $build_git_sha = "0b5fc18ea3bceb59ca4baaa261089f2490674138";
my $version = "1.0-2";
my $build_date = "2017-03-20 11:50";
my $build_git_sha = "f453673f0c118a048624b81f779965be50f278d5";
my $show_version = 0;

################################################################################
# MAIN
################################################################################

main();

exit(0);

#
# Subs
#
sub main(@) {

	if ($ARGV[0] eq "-V")
	{
		print "version:       $version\n";
		print "build date:    $build_date\n";
		print "build_git_sha: $build_git_sha\n";
		print "inicfg:        $inicfg\n";
		print "This version only handles IPv4 by design\n";
		exit 0;

	}
	my $client_ip_as_string	=	$ARGV[0];	# ipv4 address
	my $data_direction		=	$ARGV[1];	# 130.226.136.242 other 0 attack_details
	my $pps					=	$ARGV[2];	# number
	my $action				=	$ARGV[3];	# ban | unban | attack_details

	logit ("start: $0 @ARGV");

	if(!defined $client_ip_as_string or !defined $data_direction or !defined $pps or !defined $action)
	{
		logit("usage: $usage");
		exit 0;
	}

	if("$action" eq "unban")
	{
		logit("action unban ignored");
		exit 0;
	}

	# check client_ip_as_string is ipv4
	($ver, $ip, $port) = parse_v4($client_ip_as_string) or mydie "'$client_ip_as_string' not an address\n";

	# read prefs from ini file
	open my $fh, '<', $inicfg or mydie "Could not open '$inicfg' $!";
	my $section;
	my %data;

	while (my $line = <$fh>) {
		if ($line =~ /^\s*#/) {
			next;        # skip comments
		}
		if ($line =~ /^\s*$/) {
			next;    # skip empty lines
		}

		if ($line =~ /^\[(.*)\]\s*$/) {
			$section = $1;
			next;
		}

		if ($line =~ /^([^=]+?)\s*=\s*(.*?)\s*$/) {
			my ($field, $value) = ($1, $2);
			if (not defined $section) {
				logit("Error in '$inicfg': Line outside of seciton '$line'");
				next;
			}
			$data{$section}{$field} = $value;
		}
	}

	my $uuid	= $data{'globals'}{'uuid'};
	my $server	= $data{'update'}{'server'};
	my $user	= $data{'update'}{'user'};
	my $pubkey	= $data{'update'}{'pubkey'};
	my $privkey	= $data{'update'}{'privkey'};
	my $passwd	= $data{'update'}{'passwd'};

	my $mode	= $data{'globals'}{'mode'};
	my $blocktime = $data{'globals'}{'blocktime'};
	my $customernetworkid = $data{'globals'}{'customernetworkid'};

	close ($fh);


	# process tcpdump
	while (<STDIN>)
	{
		chomp $_;
		next if (/^$/);

		# fastnetmon
		if ($_ =~ /^Attack type:\s*(\w*)$/)									{ $attack_type = $1; };
		if ($_ =~ /^Initial attack power:\s*(\d).*$/)						{ $Initial_attack_power = $1; };
		if ($_ =~ /^Peak attack power:\s*(\d).*$/)							{ $Peak_attack_power = $1; };
		if ($_ =~ /^Attack protocol:\s*(\w*)$/)								{ $attack_protocol = $1; };
		if ($_ =~ /^Total incoming traffic:\s*(\d*).*$/)					{ $Total_incoming_traffic = $1; };
		if ($_ =~ /^Attack direction:\s*(\w*)$/)							{ $Attack_direction = $1; };
		if ($_ =~ /^Total outgoing traffic:\s*(\d).*$/)						{ $Total_outgoing_traffic = $1; };
		if ($_ =~ /^Total incoming pps:\s*(\d).*$/)							{ $Total_incoming_pps = $1; };
		if ($_ =~ /^Total outgoing pps:\s*(\d).*$/)							{ $Total_outgoing_pps = $1; };
		if ($_ =~ /^Total incoming flows:\s*(\d).*$/)						{ $Total_incoming_flows = $1; };
		if ($_ =~ /^Total outgoing flows:\s*(\d).*$/)						{ $Total_outgoing_flows = $1; };
		if ($_ =~ /^Average incoming traffic:\s*(\d).*$/)					{ $Average_incoming_traffic = $1; };
		if ($_ =~ /^Average outgoing traffic:\s*(\d).*$/)					{ $Average_outgoing_traffic = $1; };
		if ($_ =~ /^Average incoming pps:\s*(\d).*$/)						{ $Average_incoming_pps = $1; };
		if ($_ =~ /^Average outgoing pps:\s*(\d).*$/)						{ $Average_outgoing_pps = $1; };
		if ($_ =~ /^Average incoming flows:\s*(\d).*$/)						{ $Average_incoming_flows = $1; };
		if ($_ =~ /^Average outgoing flows:\s*(\d).*$/)						{ $Average_outgoing_flows = $1; };
		if ($_ =~ /^Incoming ip fragmented traffic:\s*(\d).*$/)				{ $Incoming_ip_fragmented_traffic = $1; };
		if ($_ =~ /^Outgoing ip fragmented traffic:\s*(\d).*$/)				{ $Outgoing_ip_fragmented_traffic = $1; };
		if ($_ =~ /^Incoming ip fragmented pps:\s*(\d).*$/)					{ $Incoming_ip_fragmented_pps = $1; };
		if ($_ =~ /^Outgoing ip fragmented pps:\s*(\d).*$/)					{ $Outgoing_ip_fragmented_pps = $1; };
		if ($_ =~ /^Incoming tcp traffic:\s*(\d).*$/)						{ $Incoming_tcp_traffic = $1; };
		if ($_ =~ /^Outgoing tcp traffic:\s*(\d).*$/)						{ $Outgoing_tcp_traffic = $1; };
		if ($_ =~ /^Incoming tcp pps:\s*(\d).*$/)							{ $Incoming_tcp_pps = $1; };
		if ($_ =~ /^Outgoing tcp pps:\s*(\d).*$/)							{ $Outgoing_tcp_pps = $1; };
		if ($_ =~ /^Incoming syn tcp traffic:\s*(\d).*$/)					{ $Incoming_syn_tcp_traffic = $1; };
		if ($_ =~ /^Outgoing syn tcp traffic:\s*(\d).*$/)					{ $Outgoing_syn_tcp_traffic = $1; };
		if ($_ =~ /^Incoming syn tcp pps:\s*(\d).*$/)						{ $Incoming_syn_tcp_pps = $1; };
		if ($_ =~ /^Outgoing syn tcp pps:\s*(\d).*$/)						{ $Outgoing_syn_tcp_pps = $1; };
		if ($_ =~ /^Incoming udp traffic:\s*(\d).*$/)						{ $Incoming_udp_traffic = $1; };
		if ($_ =~ /^Outgoing udp traffic:\s*(\d).*$/)						{ $Outgoing_udp_traffic = $1; };
		if ($_ =~ /^Incoming udp pps:\s*(\d).*$/)							{ $Incoming_udp_pps = $1; };
		if ($_ =~ /^Outgoing udp pps:\s*(\d).*$/)							{ $Outgoing_udp_pps = $1; };
		if ($_ =~ /^Incoming icmp traffic:\s*(\d).*$/)						{ $Incoming_icmp_traffic = $1; };
		if ($_ =~ /^Outgoing icmp traffic:\s*(\d).*$/)						{ $Outgoing_icmp_traffic = $1; };
		if ($_ =~ /^Incoming icmp pps:\s*(\d).*$/)							{ $Incoming_icmp_pps = $1; };
		if ($_ =~ /^Outgoing icmp pps:\s*(\d).*$/)							{ $Outgoing_icmp_pps = $1; };
		if ($_ =~ /^Network incoming traffic:\s*(\d).*$/)					{ $Network_incoming_traffic = $1; };
		if ($_ =~ /^Network outgoing traffic:\s*(\d).*$/)					{ $Network_outgoing_traffic = $1; };
		if ($_ =~ /^Network incoming pps:\s*(\d).*$/)						{ $Network_incoming_pps = $1; };
		if ($_ =~ /^Network outgoing pps:\s*(\d).*$/)						{ $Network_outgoing_pps = $1; };
		if ($_ =~ /^Average network incoming traffic:\s*(\d).*$/)			{ $Average_network_incoming_traffic = $1; };
		if ($_ =~ /^Average network outgoing traffic:\s*(\d).*$/)			{ $Average_network_outgoing_traffic = $1; };
		if ($_ =~ /^Average network incoming pps:\s*(\d).*$/)				{ $Average_network_incoming_pps = $1; };
		if ($_ =~ /^Average network outgoing pps:\s*(\d).*$/)				{ $Average_network_outgoing_pps = $1; };
		if ($_ =~ /^Average packet size for incoming traffic:\s*(\d).*$/)	{ $Average_packet_size_for_incoming_traffic = $1; };
		if ($_ =~ /^Average packet size for outgoing traffic:\s*(\d).*$/)	{ $Average_packet_size_for_outgoing_traffic = $1; };

		# tcpdump ...
		next if (! />.*$client_ip_as_string/);

		# 2016-06-08 16:18:53.299994 130.225.245.210:34859 > 130.226.136.242:5001 protocol: udp frag: 0  packets: 1 size: 1512 bytes ttl: 0 sample ratio: 1
		# date       time            src_sport               dst_dport            x         proto x   frag  x      packets  x size  x    x   ttl x     x      ratio
		# 2017-03-27 14:47:43.199756 21.30.184.209:14363 > 130.226.136.242:80 protocol: tcp flags: syn frag: 0  packets: 1 size: 60 bytes ttl: 63 sample ratio: 1
		#
		# 2017-03-27 15:32:03.071697 60.28.184.234:0 > 130.226.136.242:0 protocol: icmp frag: 0  packets: 1 size: 60 bytes ttl: 63 sample ratio: 1
		#
		if ($_ =~ /.*>.*$client_ip_as_string.*protocol:.*bytes.*ttl:.*/)
		{
			# split on tcp | udp | icmp | ???
			($date, $time, $src_sport, $andgt, $dst_dport, $str, $protocol, $str, $frag, $str, $packets, $str, $size, $str, $str, $ttl, $str, $str, $ratio) = 
			split(' ', $_);

			($src, $sport) = split(':', $src_sport);
			($dst, $dport) = split(':', $dst_dport);

			#  v   - Type 1 - Destination Prefix
			#  v   - Type 2 - Source Prefix
			#  v   - Type 3 - IP Protocol
			#  v   - Type 4 – Source or Destination Port
			#  v   - Type 5 – Destination Port
			#  v   - Type 6 - Source Port
			#  x   - Type 7 – ICMP Type
			#  x   - Type 8 – ICMP Code
			#  ?   - Type 9 - TCP flags
			#  v   - Type 10 - Packet length
			#  x   - Type 11 – DSCP
			#  ?   - Type 12 - Fragment Encoding

			# Fail-safe: only do something if everything seems ok
			# silently drop lines which does not have all info
			next if (!defined $src or !defined $sport or !defined $dst or !defined $dport or !defined $protocol or !defined $frag or !defined $packets or !defined $size or !defined $ttl or !defined $ratio or !defined $pps);

			# not an address or portnumber
			($ver, $ip, $port) = parse_v4($src, $sport) or next;
			($ver, $ip, $port) = parse_v4($dst, $dport) or next;

			# not numbers
			($ttl	=~ /[0-9]*/) or next;
			($ratio	=~ /[0-9]*/) or next;
			($pps	=~ /[0-9]*/) or next;

			# Automatic rule files:
			# customernetworkid;fastnetmoninstanceid;blocktime;destinationprefix;sourceprefix;ipprotocol;srcordestport;destinationport;icmptype;icmpcode;tcpflags;packetlength;dscp;fragmentencoding
			# ...
			# ..
			#last-line
			#print "$customernetworkid;$uuid;$blocktime;$dst;$src;$protocol;$sport;$dport;n/a;n/a;$size ttl=$ttl ratio=$ratio pps=$pps mode=$mode blocktime=$blocktime\n";
		}
		else
		{
			# non-tcpdump line ignored
			#: print "hmm :=-> $_\n";
			logit("unused input: $_");
		}
	}


#	my $ssh2 = Net::SSH2->new();
#	$ssh2->connect("$server") or mydie $!;
#
#	# auth_publickey ( username, public key, private key [, password ] )
#	my $auth = $ssh2->auth_publickey(
#		$user, $pubkey, $privkey, $passwd
#	);
#
#	my $chan2 = $ssh2->channel();
#	$chan2->blocking(1);
#
#	# send to postgres sort-of
#	$chan2->exec("$cmd\n");
#
#	print "$_" while <$chan2>;
#
#	$chan2->close;

	exit(0);
}

sub parse_v4(@) {
	my ($ip, $port) = @_;
	my @quad = split(/\./, $ip);
 
	return unless @quad == 4;
	{ return if (join('.', @quad) !~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) }	# prevent non digits from messing up next line
	for (@quad) { return if ($_ > 255) }
 
	if (!length $port) { $port = -1 }
	elsif ($port =~ /^(\d+)$/) { $port = $1 }
	else { return }
 
	my $h = join '' => map(sprintf("%02x", $_), @quad);
	return $h, $port
}
 
sub parse_v6($) {
	my $ip = shift;
	my $omits;
 
	return unless $ip =~ /^[\da-f:.]+$/i; # invalid char
 
	$ip =~ s/^:/0:/;
	$omits = 1 if $ip =~ s/::/:z:/g;
	return if $ip =~ /z.*z/;	# multiple omits illegal
 
	my $v4 = '';
	my $len = 8;
 
	if ($ip =~ s/:((?:\d+\.){3}\d+)$//) {
		# hybrid 4/6 ip
		($v4) = parse_v4($1)	or return;
		$len -= 2;
 
	}
	# what's left should be v6 only
	return unless $ip =~ /^[:a-fz\d]+$/i;
 
	my @h = split(/:/, $ip);
	return if @h + $omits > $len;	# too many segments
 
	@h = map( $_ eq 'z' ? (0) x ($len - @h + 1) : ($_), @h);
	return join('' => map(sprintf("%04x", hex($_)), @h)).$v4;
}
 
sub parse_ip($) {
	my $str = shift;
	$str =~ s/^\s*//;
	$str =~ s/\s*$//;
 
	if ($str =~ s/^((?:\d+\.)+\d+)(?::(\d+))?$//) {
		return 'v4', parse_v4($1, $2);
	}
 
	my ($ip, $port);
	if ($str =~ /^\[(.*?)\]:(\d+)$/) {
		$port = $2;
		$ip = parse_v6($1);
	} else {
		$port = -1;
		$ip = parse_v6($str);
	}
 
	return unless $ip;
	return 'v6', $ip, $port;
}

sub logit(@)
{
    my $msg = join(' ', @_);
    syslog("user|err", "$msg");
    my $now = strftime "%H:%M:%S (%Y/%m/%d)", localtime(time);
    print STDOUT "$now: $msg\n" if ($verbose);

    open(LOGFILE, ">>$logfile");
    print LOGFILE "$now: $msg\n";
    close(LOGFILE);
}

sub mydie(@)
{
	logit(@_);
	exit(0);
}
