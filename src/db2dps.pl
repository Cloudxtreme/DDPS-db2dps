#!/usr/bin/perl -w
#
# $Header$
#
#++
# #### Name db2dps
#
# Database / rule manipulation for DDPS
#
# #### Synopsis
# 
#  ``db2dps [-V] [-v] [-d] [-s seconds]``
# 
# ### Description
#
# ``db2dps`` process new _rulefiles_, and maintain rules in the database wile
# sending BGP flowspec updates to a number of BGP hosts. ``db2dps`` runs as
# a daemon controlled by systemd.
#
# ### Options
#
#   - **-V**: print version information and exit
#   - **-v**: verbose and run in foreground
#   - **-d**: demonise
#   - **-s** _seconds_: sleep time between database scan. Default is 20 seconds
#
# #### Pseudo code
# 
# ```bash
# read configuration || fail
# check args: print version and exit | demonise | run in foreground
# 
# connect to database || exit fail
# 
# query(all my networks)
# 
# while true; do
# {
#   if [ exit required ]
#   {
#     break loop
#     close database connection
#     exit normal
#   }
#   else
#   {
#     sleep except seconds on first loop
#   }
#  
#    if [ exist (new files with rules from fastnetmon) ]
#      if (query(insert rules in database) == OK)
#         delete(rulefile) or warn
# 
#   foreach bgphost do
#   {
#     mkrulebase("announce", bgphost)
#     {
#        if (bgphost requires all rules)
#           query(all rules)
#        else
#           query(NOT isactivated and NOT expired records)
#        continue if (query empty)
#        {
#          if (destination is within all my networks)
#          {
#            build rules suitable for bgphost
#            send rulebase to bgp host || warn
#            /* notice: this may block */
#          }
#          else
#          {
#            warn about attempt to filter for external network
#          }
#       }
#     }
#   }
#   query(set isactivated for all announced rules in database)
# 
#   foreach bgphost do
#   {
#     mkrulebase("withdraw", bgphost)
#     {
#        query(all isactivated rules)
#        select rules which are expired AND does not match a non-expired rule
#        foreach (bgphosts)
#        {
#          if (destination is within all my networks)
#          {
#            build rules suitable for bgphost
#            send rulebase to bgp host || warn
#            /* notice: this may block */
#          }
#          else
#          {
#            warn about attempt to filter for external network
#          }
#       }
#     }
#   }
#   query(set isexpired for withdrawn rules in database)
# }
# 
# close database connection and exit normal
# ```
#
# ### Author
#
# Niels Thomas Haugård, niels.thomas.haugaard@i2.dk
#
# ### Bugs
#
# Probably. Please report them to the the author or the DDPS group. Please
# notice this is early work.
#
#--
# ## Requirements -- see Makefile
#		sudo apt-get install libnet-openssh-compat-perl liblist-moreutils-perl
#		apt-get install libnet-openssh-compat-perl
#		apt-get -y install libnet-ssh2-perl libproc-daemon-perl
#		apt -y install libnetaddr-ip-perl libtypes-path-tiny-perl
#

#
# Requirements
#
use strict;
use warnings;
use sigtrap qw(die normal-signals);
use DBI;				# database

use Sys::Syslog;		# only needed for logit
use POSIX;				# only needed for logit
use Getopt::Long qw(:config no_ignore_case);
use Net::SSH2;			# ssh v2 access to postgres db
use List::MoreUtils qw(uniq);
use Proc::Daemon;
use Socket qw( inet_aton );
use NetAddr::IP;
use Path::Tiny;

#
# prototypes
#
sub main(@);
sub logit(@);
sub mydie(@);
sub parse_ip($);
#sub parse_ip6($);
sub parse_v4(@);
sub mkrulebase($$);
sub ip2long($);
sub in_subnet($$);
sub processnewrules();

# URL's with useful information
# http://www.microhowto.info/howto/connect_to_a_postgresql_database_using_perl_dbi.html
# https://www.tutorialspoint.com/postgresql/postgresql_perl.htm
# http://www.techrepublic.com/article/retrieve-data-from-a-postgresql-database-using-the-perl-dbi/
# https://www.compose.com/articles/connecting-and-loading-data-to-postgresql-with-perl/
# https://www.postgresql.org/docs/9.3/static/plperl.html
# http://www.easysoft.com/developer/languages/perl/dbd_odbc_tutorial_part_2.html
# http://search.cpan.org/~timb/DBI-1.636/DBI.pm

my $driver	= "Pg"; 

#
# Global vars
#
my $usage = "\n$0 -s seconds [-v | -d ] \n";

my $verbose = "";
my $sleeptime = 10;
my $rundaemon = 0;
my $continue = 1;

# included from version.pm
# my $build_date = "2017-02-16 15:16";
# my $build_git_sha = "0b5fc18ea3bceb59ca4baaa261089f2490674138";
#INCLUDE_VERSION_PM
my $show_version = 0;

my $logfile = "/opt/db2dps/tmp/" . "logfile.txt";		# no longer used
my $inicfg	= "/opt/db2dps/etc/db.ini";

my @implemented_flowspecruleid;

# All BGP rule values
my ($flowspecruleid, $direction, $destinationprefix, $sourceprefix,
		$ipprotocol, $srcordestport, $destinationport, $sourceport, $icmptype,
		$icmpcode, $tcpflags, $packetlength, $dscp, $fragmentencoding
	);

my $sql_query = "";

my $section;
my %data;
my $db							= "";
my $rulebase					= "";
my $dbuser						= "";
my $dbpass						= "";

my $allmynetworks				= "";
my $newrules					= "";
my $newrulesdir					= "";
my $remove_expired_rules		= "";
my $hostlist					= "";
my $datadir						= "";
my $all_rules					= "";
my $shutdown					= "";
my $tcpudpdrop					= "";
my $icmpdrop					= "";
my $ipdrop						= "";
my $blackhole					= "";
my $ratelimit					= "";
my $update_rules_when_announced	= "";
my $update_rules_when_expired	= "";
my $action						= "";
my $validfrom					= "";
my $validto						= "";

my $dbh;
my @unique_implemented_flowspecruleid;

################################################################################
# MAIN
################################################################################

main();

exit(0);

#
# Subs
#
sub main(@) {
	if (!GetOptions(
		'inicfg|f=s'		=> \$inicfg,
		'sleeptime|s=s'		=> \$sleeptime,
		'verbose|v'			=> \$verbose,
		'daemonize|d'		=> \$rundaemon,
		'show_version|V'	=> \$show_version
	))
	{
		print<<"EOF";

	Usage:
		$0 [-v|-d][-s sec][-f file]
		$0 -V
		
		-V: print version and exit
		-v: be verbose
		-d: daemonize
		-f file: use config file
		-s sec: sleep seconds between each database query

EOF
		exit 0;
	}

	$sleeptime = 20 unless defined($sleeptime);

	logit("verbose		= $verbose");
	logit("daemonize	= $rundaemon");
	logit("sleeptime	= $sleeptime");
	
	# Check arguments
	if ($show_version eq 1)
	{
		print "version:       $version\n";
		print "build date:    $build_date\n";
		print "build_git_sha: $build_git_sha\n";
		print "inicfg:        $inicfg\n";
		print "sleeptime:     $sleeptime\n";
		print "This version only handles IPv4 by design\n";
		exit 0;
	}

	if ($verbose eq 1)
	{
		if ($rundaemon eq 1)
		{
			printf("verbose and daemonize are mutal exclusive\n");
			exit 1;
		}
	}

	open my $fh, '<', $inicfg or mydie "Could not open '$inicfg' $!";

	while (my $line = <$fh>) {
		if ($line =~ /^\s*#/) {
			next;		# skip comments
		}
		if ($line =~ /^\s*$/) {
			next;		# skip empty lines
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

	$db								= $data{'general'}{'dbname'};
	$rulebase						= $data{'general'}{'rulebase'};
	$dbuser							= $data{'general'}{'dbuser'};
	$dbpass							= $data{'general'}{'dbpassword'};

	$newrulesdir					= $data{'general'}{'newrulesdir'};		# dir where new rules are uploaded. P.t. only one dir

	$newrules						= $data{'general'}{'newrules'};
	$remove_expired_rules			= $data{'general'}{'remove_expired_rules'};
	$hostlist						= $data{'general'}{'hostlist'};
	$datadir						= $data{'general'}{'datadir'};
	$all_rules						= $data{'general'}{'all_rules'};
	$shutdown						= $data{'general'}{'shutdown'};
	$tcpudpdrop						= $data{'general'}{'tcpudpdrop'};
	$icmpdrop						= $data{'general'}{'icmpdrop'};
	$ipdrop							= $data{'general'}{'ipdrop'};
	$blackhole						= $data{'general'}{'blackhole'};
	$ratelimit						= $data{'general'}{'ratelimit'};
	$update_rules_when_announced	= $data{'general'}{'update_rules_when_announced'};
	$update_rules_when_expired		= $data{'general'}{'update_rules_when_expired'};

	# my $uuid	= $data{'globals'}{'uuid'} . "-" . $data{'globals'}{'customer'};

	close ($fh);

	logit("database	= $db");
	logit("dbadmin		= $dbuser");

	# from http://stackoverflow.com/questions/766397/how-can-i-run-a-perl-script-as-a-system-daemon-in-linux
	if ($rundaemon eq 1)
	{
		logit("daemonizing ...");
		Proc::Daemon::Init;
		$SIG{TERM} = sub { $continue = 0 };
		logit("daemonizing done");
	}

	# Connect to the database
	my $dsn = "DBI:$driver:dbname=$db;host=127.0.0.1;port=5432";
	$dbh = DBI->connect($dsn, $dbuser, $dbpass, { RaiseError => 1 }) or mydie $DBI::errstr;

	# Trace to a file for debugging ..
	# $dbh -> trace(1, '/tmp/tracelog.txt');

	logit("database connected successfully");

	# Not sure this is good: all our network (forskningsnet) kept as userid 0; has placed it in
	# the db.ini instead
	#
	# fetch list of all my neworks
	#$sql_query = $data{'general'}{'allmynetworks'};
	# logit("query general::allmynetworks ... ");
	# my $sth = $dbh->prepare($sql_query);
	# $sth->execute();
	# {
	# 	my @tmparr;
	# 	while (my @row = $sth->fetchrow_array)
	# 	{
	# 		#my $customernetworkid	= $row[0] ? $row[0] : '';
	# 		#my $customerid			= $row[1] ? $row[1] : '';
	# 		#my $name				= $row[2] ? $row[2] : '';
	# 		#my $kind				= $row[3] ? $row[3] : '';
	# 		#my $net_cidr			= $row[4] ? $row[4] : '';
	# 		#my $description		= $row[5] ? $row[5] : '';
	# 		push ($allmynetworks, $row[4]);
	# 	}
	# 	$sth->finish();
	# 	#$allmynetworks = join(', ', $allmynetworks);
	# }

	my $allmynetworks = $data{'general'}{'ournetworks'};
	logit("All allowed destination networks: $allmynetworks");

	my $first_loop = 1;

	logit ("starting main loop");
	loop: while ($continue)
	{
		if (-e $shutdown)
		{
		 	logit("shutdown file $shutdown found, exiting");
			unlink $shutdown;
			last loop;
		}
		if ($first_loop == 1)
		{
			 $first_loop = 0;
		}
		else
		{
			sleep $sleeptime;
		}

		processnewrules();

		# announce new or all rules
		# For each bgp-host do

		mkrulebase("announce", $hostlist);
		logit("announcement done for all exabgp hosts");

		# update database with all new isactivated records || warn
		@unique_implemented_flowspecruleid = uniq @implemented_flowspecruleid;
		if ($#unique_implemented_flowspecruleid >= 0)
		{
			logit("setting isactivated for $#unique_implemented_flowspecruleid rules in db");
			logit("isactivated ids: @unique_implemented_flowspecruleid");
			my $unique_implemented_flowspecruleid = join(', ', @implemented_flowspecruleid);

			# careful with sql statemets and " in db.ini ...
			$sql_query = $update_rules_when_announced;
			$sql_query =~ s/\Q%s\E/$unique_implemented_flowspecruleid/g;
			logit("$sql_query");

			my $sth = $dbh->prepare($sql_query);
			$sth->execute();
			$sth->finish();
			undef (@implemented_flowspecruleid);
		}

		mkrulebase("withdraw", $hostlist);
		@unique_implemented_flowspecruleid = uniq @implemented_flowspecruleid;
		if ($#unique_implemented_flowspecruleid >= 0)
		{
			logit("setting isexpired for $#unique_implemented_flowspecruleid rules in db");
			logit("isexpired ids: @unique_implemented_flowspecruleid");
			my $unique_implemented_flowspecruleid = join(', ', @implemented_flowspecruleid);

			# careful with sql statemets and " in db.ini ...
			$sql_query = $update_rules_when_expired;
			$sql_query =~ s/\Q%s\E/$unique_implemented_flowspecruleid/g;
			logit("$sql_query");

			my $sth = $dbh->prepare($sql_query);
			$sth->execute();
			$sth->finish();
			undef (@implemented_flowspecruleid);
		}
		logit("withdraw done for all exabgp hosts");
	} # main loop exit here

	$dbh->disconnect();

	logit("bye");
}

#
# subs below
#

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

	#open(LOGFILE, ">>$logfile");
	#print LOGFILE "$now: $msg\n";
	#close(LOGFILE);
}

sub mydie(@)
{
	logit(@_);
	exit(0);
}

sub mkrulebase($$)
{
	my $type = shift;
	my $hostlist = shift;

	logit("TYPE: $type");
	logit("hostlist: $hostlist");

	# announce new or all rules
	# For each bgp-host do
	logit("host list: $hostlist");
	my @hostlist = split(' ', $hostlist);
	foreach my $host (@hostlist)
	{
		my $sshuser			= $data{$host}{'sshuser'};			$sshuser =~ tr/\"//d;
		my $identity_file	= $data{$host}{'identity_file'};	$identity_file =~ tr/\"//d;
		my $public_key		= $data{$host}{'public_key'};		$public_key =~ tr/\"//d;
		my $filtertype		= $data{$host}{'filtertype'};		$filtertype =~ tr/\"//d;
		my $exabgp_pipe		= $data{$host}{'exabgp_pipe'};		$exabgp_pipe =~ tr/\"//d;

		logit("preparing $type rules for $host");

		if ($type eq lc "announce")
		{
			# if [ a full feed is required ]
			# only relevant for announcements
			my $filepath = $datadir . "/" . $host;
			if (-e $filepath )
			{
				logit("file $filepath found $host require full feed");
				unlink $filepath;
				# query all records || continue
				logit("querying for all rules");
				$sql_query = $data{'general'}{'all_rules'};
			}
			else	# continue
			{
				$sql_query = $data{'general'}{'newrules'};
			}
		}
		elsif($type eq lc "withdraw")
		{
			$sql_query = $data{'general'}{'remove_expired_rules'}
		}
		else
		{
			mydie("argument type to mkrulebase must be 'announce' or 'withdraw' not '$type'");
		}

		my $sth = $dbh->prepare($sql_query);
		$sth->execute();

		# print rules to rulebase
		open (my $fh, '>', $rulebase) || mydie "open write '$rulebase' failed: $!";

		logit("start reading rows from db ... ");
		# http://www.perlmonks.org/?node_id=312625
		# $sth->execute();
		# my $count = 0;
		# while (my $row = $sth->fetchrow_arrayref()) {
   		#	process_row($row);
   		#	$count++;
		# }
		# unless ($count) {
   		#	do_something_else();
		# }
		#

		while (my @row = $sth->fetchrow_array)
		{	
			#  gsed '/#/d; /newrulesdir/d; /newrules/!d; s/.*=.*select//; s/ from.*$//;s/,/\n/g; s/^[\t ]*//' db.ini  | nl -v 0

			logit("read: ",  join(",", map {$_ ? $_ : "''"} @row) );

			# initialize
			$flowspecruleid = $direction = $destinationprefix = $sourceport = $ipprotocol = $srcordestport = $destinationport = $sourceport = $sourceport = $icmptype = $icmpcode = $tcpflags = $packetlength = $dscp = $fragmentencoding = $action = $validfrom = $validto = "";

			# required as some db fields are null
			$flowspecruleid     = $row[0] ? $row[0] : '';
            $direction          = $row[1] ? $row[1] : '';
            $destinationprefix  = $row[2] ? $row[2] : '';
            $sourceprefix       = $row[3] ? $row[3] : '';
            $ipprotocol         = $row[4] ? $row[4] : '';
            $srcordestport      = $row[5] ? $row[5] : '';
            $destinationport    = $row[6] ? $row[6] : '';
            $sourceport         = $row[7] ? $row[7] : '';
            $icmptype           = $row[8] ? $row[8] : '';
            $icmpcode           = $row[9] ? $row[9] : '';
            $tcpflags           = $row[10] ? $row[10] : '';
            $packetlength       = $row[11] ? $row[11] : '';
            $dscp               = $row[12] ? $row[12] : '';
            $fragmentencoding   = $row[13] ? $row[13] : '';
            $action             = $row[14] ? $row[14] : '';
            $validfrom          = $row[15] ? $row[15] : '';		# 2017-02-19 23:04:30.682073+01
            $validto            = $row[16] ? $row[16] : '';		# 2017-02-19 23:04:30.682073+01
																# Time::HiRes only have this 
																# xxxx-xx-xx-xx:xx:xx.xxx
																# so valid* must be truncated

			# Prevent incomplete rules from entering the flow: if an required field fails
			# set $ipprotocol to unknown ('')
			$flowspecruleid			= $flowspecruleid		? $flowspecruleid		: "";
			$direction				= $direction			? $direction			: "";
			$destinationprefix		= $destinationprefix	? $destinationprefix	: "";
			$sourceprefix			= $sourceprefix			? $sourceprefix			: "";
			$ipprotocol				= $ipprotocol			? $ipprotocol			: "";
			$srcordestport			= $srcordestport		? $srcordestport		: "";
			$destinationport		= $destinationport		? $destinationport		: "";
			$sourceport				= $sourceport			? $sourceport			: "";
			$icmptype				= $icmptype				? $icmptype				: "";
			$icmpcode				= $icmpcode				? $icmpcode				: "";
			$tcpflags				= $tcpflags				? $tcpflags				: "";
			$packetlength			= $packetlength			? $packetlength			: "";
			$dscp					= $dscp					? $dscp					: "";
			$fragmentencoding		= $fragmentencoding		? $fragmentencoding		: "";
			$action					= $action				? $action				: "discard";
			$validfrom				= $validfrom			? $validfrom			: "";
			$validto				= $validto				? $validto				: "";

			logit("debug:");
			logit("number of collums in \@row:$#row");
			logit("flowspecruleid: $flowspecruleid");
			logit("direction: $direction");
			logit("destinationprefix: $destinationprefix");
			logit("sourceprefix: $sourceprefix");
			logit("ipprotocol: $ipprotocol");
			logit("srcordestport: $srcordestport");
			logit("destinationport: $destinationport");
			logit("sourceport: $sourceport");
			logit("icmptype: $icmptype");
			logit("icmpcode: $icmpcode");
			logit("tcpflags: $tcpflags");
			logit("packetlength: $packetlength");
			logit("dscp: $dscp");
			logit("fragmentencoding: $fragmentencoding");
			logit("action: $action");
			logit("validfrom: $validfrom");
			logit("validto: $validto");

			#
			#  2554, in, 130.226.136.242, , udp, , , , , , , , 60, , , 2017-04-26 17:05:38.492843+02, 2017-04-26 17:15:38.492843+02,   -- no validto
			#  If no 'action' then $action = $validfrom and  $validto = "" ??????
			#
			logit("read from db: $flowspecruleid, $direction, $destinationprefix, $sourceport, $ipprotocol, $srcordestport, $destinationport, $sourceport, $sourceport, $icmptype, $icmpcode, $tcpflags, $packetlength, $dscp, $fragmentencoding, $action, $validfrom, $validto");

			# append /32 to prefix if not cidr and assume just an IP address
			if ($destinationprefix ne "")
			{
				if ($destinationprefix !~ m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$| )
				{
					$destinationprefix = $destinationprefix . "/32";
				}
			}

			if ($sourceprefix ne "")
			{
				if ($sourceprefix !~ m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$| )
				{
					$sourceprefix = $sourceprefix . "/32";
				}
			}

			################################################################################
			# TODO
			# only announce / withdraw rules within walidfrom / validto.
			# A special check is also needed to prevent rules with long expire time to be
			# withdrawn by identical rules with shorter ones.
			# Keep a copy of the prev. rule
			# - select and sort validto DESC, (see solving-overlapping-rule-problem.sh)
			#   ie. chage 'withdraw' so order by is validto DESC, select all activated rules
			#	and match those which has validto < now and doesn't have a matching rule
			#	shadowing for it
			# - if validto > now() then discard rule
			# - if (all fields except validto == prev. rule fields) then discard
			#
			# Later it will also be here a whitelist check has to be done
			#
			# BGP flow types should go in an external config file and I should use fprintf(fmt, ...)
			################################################################################	


			# Last line of defence to prevent wron announcements: Do not
			# announce / withdraw networks outside our constituency
			{
				my $dst_subnet = new NetAddr::IP $destinationprefix;

				my $destinationprefix_is_within_my_network = 0;

				foreach my $mynetwork (split ' ', $allmynetworks)
				{
					my $subnet = new NetAddr::IP $mynetwork;
					if ($dst_subnet->within($subnet))
					{
							logit("dst $dst_subnet is within $subnet");
							$destinationprefix_is_within_my_network = 1;
					}
				}
				if ($destinationprefix_is_within_my_network == 1)
				{
					logit("program error: rule ignored, outside our constituency destinationprefix=$destinationprefix sourceprefix=$sourceprefix ipprotocol=$ipprotocol validfrom=$validfrom validto=$validto");
				}
			}

			# The prev. rule -- ignored the on first rule
			my	 (	$prev_flowspecruleid, $prev_direction, $prev_destinationprefix,
					$prev_sourceprefix, $prev_ipprotocol, $prev_srcordestport,
					$prev_destinationport, $prev_sourceport, $prev_icmptype,
					$prev_icmpcode, $prev_tcpflags, $prev_packetlength,
					$prev_dscp, $prev_fragmentencoding, $prev_validfrom, $prev_validto
				);

			# preserve implemented_flowspecruleid - duplicates will be removed later
			push(@implemented_flowspecruleid, $flowspecruleid);

			my $filtertype = $data{$host}{'filtertype'};		$filtertype =~ tr/\"//d;
			if ($filtertype eq lc 'flowspec')
			{
				# build different rule(s) for: ip | icmp | tcp | udp and print to file
				# TODO
				# this has to be extented later with fragments, ttl, size etc
				# and e.g. rate-limit 9600 instead of discard by readming from
				# 'action' field

				my $rule = "";

				# tcp‐flags [ fin | syn | rst | push | ack | urgent ];
				#fragment [ not‐a‐fragment | dont‐fragment | is‐fragment | first‐fragment | last‐fragment ];

				if (length $sourceprefix)		{ $sourceprefix			= "source "				. $sourceprefix			. ";" }
				if (length $destinationprefix)	{ $destinationprefix	= "destination "		. $destinationprefix	. ";" }
				if (length $destinationport)	{ $destinationport		= "destination-port "	. $destinationport		. ";" }
				if (length $ipprotocol)			{ $ipprotocol			= "protocol "			. $ipprotocol			. ";" }
				if (length $tcpflags)			{ $tcpflags				= "tcp-flags "			. $tcpflags				. ";" }
				if (length $packetlength)		{ $packetlength			= "packet-length "		. $packetlength			. ";" }

				if ($ipprotocol  !~ /(icmp|tcp|udp|1|6|17)/)			# remove any tcp/udp/icmp specific things, if any
				{
					$tcpflags			= "";
					$icmptype			= "";
					$srcordestport		= "";
					$sourceport			= "";
					$destinationport	= "";
				}


				if ($ipprotocol =~ /icmp/)								# remove any tcp/udp specific things, if any
				{
					$destinationport	= "";
					$sourceport			= "";
					$tcpflags			= "";
				}

				if ($ipprotocol =~ /udp/)								# remove any tcp/icmp specific things, if any
				{
					$tcpflags			= "";
					$icmptype			= "";
					$tcpflags = "";
				}

				# final rule
				$rule = "$type flow route $flowspecruleid { match { $sourceprefix $destinationprefix $destinationport $ipprotocol $tcpflags $packetlength } then { $action } } }";
				logit("rule: $rule");
			}
			elsif ($filtertype eq lc 'blackhole')
			{
				logit("filtertype 'blackhole' not supported");
			}
			else
			{
				logit("unknown filtertype '$filtertype' not supported");
			}
		}
		close $fh;		# rulebase
		$sth->finish();

		# send $rulebase to $host:exabgp_pipe if we have any rules
		# This implementation may block everything if the scp transfer hangs
		# Fix - in C - with https://www.libssh2.org/examples/sftp_write_sliding.html
		# have AMD fix exabgp so we can scp to the pipe again or see
		# https://gist.github.com/melo/2829330
		# to do an scp (r, tmpfile) ; exec(sudo cat tmpfile > ....)

		my @unique_implemented_flowspecruleid = uniq @implemented_flowspecruleid;
		if ($#unique_implemented_flowspecruleid >= 0)
		{
			my $i = $#unique_implemented_flowspecruleid + 1;
			logit("sending $i rules to $host");
			my $ssh2 = Net::SSH2->new(timeout => 100);								# connection timeout, not command timeout
			if (! $ssh2->connect($host))
			{
				mydie("Failed connection to $host");
			}
			if (! $ssh2->auth_publickey($sshuser,$public_key,$identity_file) )
			{
				mydie("FAILED SCP public/private key authentication for $sshuser to $host");
			}

			if (! $ssh2->scp_put($rulebase, $exabgp_pipe))
			{
				logit("failed transfer $type $rulebase to $host:$exabgp_pipe");
				$ssh2->disconnect();
			}
			else
			{
				logit("succesfully transfered $type $rulebase to $host:$exabgp_pipe");
				$ssh2->disconnect();
			}
		}
		else
		{
			logit("no $type rules: update $host not needed");
		}

	}	# end foreach host in hostlist announce ...
}

sub processnewrules()
{
	# Check for new rules. Read all rule files execpt those
	# not ending with "last-line"
	# sort rules and add to database && delete rulefiles || warn

	my @rulefiles = ();
	my $file_finished_ok_string = "last-line";
	my $document;
	logit("check for new rules in '$newrulesdir' ... ");
	opendir (DIR, $newrulesdir) or die $!;
	while ( my $node = readdir(DIR) )
	{
		next if ($node =~ /^\./);
		push (@rulefiles, $node);
	}
	closedir DIR;
	my $i = $#rulefiles + 1;
	logit("found $i files in '$newrulesdir'");

	foreach my $r (@rulefiles)
	{
		my $file_finished_ok_string = "last-line";

		my $file	= path($newrulesdir . "/" . $r);
		my $head; my $tail; my $type; my $version; my $attack_info;

		my $tmp;
		($head) = $file->lines( {count =>  1}); chomp($head);
		($tail)	= $file->lines( {count => -1}); chomp($tail);

		($tmp, $type, $version, $attack_info) = split(';', $head);
		chomp($attack_info);

		my @lines = $file->lines_utf8;
		my ($action,$customerid,$uuid,$fastnetmoninstanceid,$administratorid,$blocktime,$dst,$src,$protocol,$sport,$dport,$icmp_type,$icmp_code,$flags,$length,$ttl,$dscp,$frag);

		if ($head !~ /head/)						{ logit("$file NOT ok: missing head");						next;}
		if ($tail !~ /$file_finished_ok_string/)	{ logit("$file NOT ok: missing $file_finished_ok_string");	next;}
		if ($#lines < 2)							{ logit("$file NOT ok: lines $#lines < 2");					next;}

		$action = "discard";	# default action

		logit("$file ok type=$type ver=$version attack_info=$attack_info lines=$#lines");

		# process rules and add to database
		if ($attack_info =~ /_flood/)
		{
			chomp($lines[1]);
			($customerid,$uuid,$fastnetmoninstanceid,$administratorid,$blocktime,$dst,$src,$protocol,$sport,$dport,$dport,$icmp_type,$icmp_code,$flags,$length,$ttl,$dscp,$frag) = split(';', $lines[1]);
			$src = "null";
			if ($attack_info =~ /icmp_flood/)
			{
				$action	= "discard";
				$dport	= "null";
				$sport	= "null";
			}
			if ($attack_info =~ /syn_flood/)
			{
				$action	= "rate-limit 9600";
				$sport	= "null";
			}
			if ($attack_info =~ /udp_flood/)
			{
				$action	= "rate-limit 9600";
				$dport	= "null";
				$sport	= "null";
			}
			#
			# TODO
			# Implementation of mitigation rules (see DDPS-db2dps/docs/best-practise-volumetric-ddos-mitigation.md) below

			# if ($attack_info =~ /ip_fragmentation_flood/)
			# if ($attack_info =~ /DNS amplification/)
			# if ($attack_info =~ /NTP amplification/)
			# if ($attack_info =~ /SSDP amplification/)
			# if ($attack_info =~ /SNMP amplification/)
			logit("insert into ... $uuid/$fastnetmoninstanceid|$administratorid dest:$dst proto:$protocol port:$dport length:$length frag:$frag action:$action");
			
			# quote everything except null and false
			$sql_query = << "END_OF_QUERY"; 
insert into flow.flowspecrules
(
	flowspecruleid, customerid, rule_name,
	administratorid,
	direction, validfrom, validto,
	fastnetmoninstanceid,
	isactivated, isexpired, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport,
	icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding, action
)
values
(
	(select coalesce(max(flowspecruleid),0)+1 from flow.flowspecrules), '$customerid', '$uuid',
	'$administratorid',
	'in', now(), now()+interval '$blocktime minutes',
	'$fastnetmoninstanceid',
	'false', 'false', '$dst', '$src', '$protocol', '$dport', '$dport', '$sport',
	'$icmp_type', '$icmp_code', '$flags', '$length', '$dscp', '$frag', '$action'
);
END_OF_QUERY

			$sql_query =~ s/'false'/false/g;
			$sql_query =~ s/'null'/null/g;

			#print "$sql_query\n";

			my $sth = $dbh->prepare($sql_query)	or logit("Failed in statement prepare: $dbh->errstr");
			$sth->execute()						or logit("Failed to execute statement: $dbh->errstr");

			unlink $file or logit("Could not unlink $file $!");
		}
		else
		{
			# TODO
			# loop all lines 
			# {
			# 	$sql_query = " .... ";

			# $sql_query =~ s/'false'/false/g;
			# $sql_query =~ s/'null'/null/g;

			# my $sth = $dbh->prepare($sql_query)	or logit("Failed in statement prepare: $dbh->errstr");
			# $sth->execute()						or logit("Failed to execute statement: $dbh->errstr");

			# # remove all files in @rulefiles
			# # unlink $file or logit("Could not unlink $file $!");
			# }
			#
		}

	}
	#logit("Exit in file", __FILE__, ", line:", __LINE__, ". Done");
	#exit 0;	# exit on debug
}


__DATA__

################################################################################
# Code bits
################################################################################
presission time replacement for now():

use Time::HiRes qw(time);
use POSIX qw(strftime);

my $t = time;
my $date = strftime "%Y-%m-%d %H:%M:%S", localtime $t;
$date .= sprintf ".%03d", ($t-int($t))*1000; # without rounding

print $date, "\n";
print "2017-02-19 23:04:30.682073+01\n";

#print "----\n";
#my $time = gettimeofday; # Returns ssssssssss.uuuuuu in scalar context
#print qq|$time{'yyyymmdd hh:mm:ss.mmm', $time}\n|;
print "----\n";

################################################################################
# The following code:

# white list with NetAddr::IP
apt install libnetaddr-ip-perl

use NetAddr::IP;
my $subnet = NetAddr::IP->new('10.0.0.0/24');
#my $whitelist = new NetAddr::IP "10.0.0.0", "255.0.0.0";
my $whitelist = new NetAddr::IP "10.0.0.0/8";

print "$subnet: ", $subnet->addr, " with mask ", $subnet->mask, "\n" ;
if ($subnet->within($whitelist))
{
	print "$subnet is within $whitelist\n";
}

#
# replaces all this
#

#my $ip = $ARGV[0];
#my $subnet = $ARGV[1];
#
#sub in_subnet($$)
#{
#if( in_subnet( $ip, $subnet ) )
#{
#	print "It's in the subnet\n";
#}
#else
#{
#	print "It's NOT in the subnet\n";
#}
#

# check if an ipv4 subnet is part of an ipv4 (sub-)net
sub in_subnet($$)
{
	my $ip = shift;
	my $subnet = shift;

	my $ip_long = ip2long( $ip );

	if( $subnet=~m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$| )
	{
		my $subnet = ip2long( $1 );
		my $mask = ip2long( $2 );

		if( ($ip_long & $mask)==$subnet )
		{
			return( 1 );
		}
	}
	elsif( $subnet=~m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$| )
	{
		my $subnet = ip2long( $1 );
		my $bits = $2;
		my $mask = -1<<(32-$bits);

		$subnet&= $mask;

		if( ($ip_long & $mask)==$subnet )
		{
			return( 1 );
		}
	}
	elsif( $subnet=~m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.)(\d{1,3})-(\d{1,3})$| )
	{
		my $start_ip = ip2long( $1.$2 );
		my $end_ip = ip2long( $1.$3 );

		if( $start_ip<=$ip_long and $end_ip>=$ip_long )
		{
			return( 1 );
		}
	}
	elsif( $subnet=~m|^[\d\*]{1,3}\.[\d\*]{1,3}\.[\d\*]{1,3}\.[\d\*]{1,3}$| )
	{
		my $search_string = $subnet;

		$search_string=~s/\./\\\./g;
		$search_string=~s/\*/\.\*/g;

		if( $ip=~/^$search_string$/ )
		{
			return( 1 );
		}
	}

	return( 0 );
}

sub ip2long($)
{
	return( unpack( 'N', inet_aton(shift) ) );
}

