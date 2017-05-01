#!/usr/bin/perl -w
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

my $driver	= "Pg"; 

#
# Global vars
#
my $usage = "\n$0 -s seconds [-v | -d ] \n";

my $verbose = "";
my $sleeptime = 10;
my $rundaemon = 0;
my $continue = 1;

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
sub main(@)
{
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

	if ($rundaemon eq 1)
	{
		logit("daemonizing ignored here ...");
	}

	# Connect to the database
	my $dsn = "DBI:$driver:dbname=$db;host=127.0.0.1;port=5432";
	$dbh = DBI->connect($dsn, $dbuser, $dbpass, { RaiseError => 1 }) or mydie $DBI::errstr;

	# Trace to a file for debugging ..
	# $dbh -> trace(1, '/tmp/tracelog.txt');

	logit("database connected successfully");

	my $allmynetworks = $data{'general'}{'ournetworks'};
	logit("All allowed destination networks: $allmynetworks");

	my $first_loop = 1;

	logit ("starting main loop");
	loop: while ($continue)
	{
		$sql_query = $data{'general'}{'all_rules'};
		logit("$sql_query");

		my $sth = $dbh->prepare($sql_query);
		$sth->execute();
	
		while (my @row = $sth->fetchrow_array)
		{	
			#  gsed '/#/d; /newrulesdir/d; /newrules/!d; s/.*=.*select//; s/ from.*$//;s/,/\n/g; s/^[\t ]*//' db.ini  | nl -v 0

			logit("read: ",  join(",", map {$_ ? $_ : "''"} @row) );

	#		use Data::Dumper qw(Dumper);
	#		print Dumper \@row;

			$flowspecruleid = $direction = $destinationprefix = $sourceprefix = $ipprotocol = $srcordestport = $destinationport = $sourceport = $icmptype = $icmpcode = $tcpflags = $packetlength = $dscp = $fragmentencoding = $action = $validfrom = $validto = "";

			$flowspecruleid		= $row[0] ? $row[0] : '';
			$direction			= $row[1] ? $row[1] : '';
			$destinationprefix	= $row[2] ? $row[2] : '';
			$sourceprefix		= $row[3] ? $row[3] : '';
			$ipprotocol			= $row[4] ? $row[4] : '';
			$srcordestport		= $row[5] ? $row[5] : '';
			$destinationport	= $row[6] ? $row[6] : '';
			$sourceport			= $row[7] ? $row[7] : '';
			$icmptype			= $row[8] ? $row[8] : '';
			$icmpcode			= $row[9] ? $row[9] : '';
			$tcpflags			= $row[10] ? $row[10] : '';
			$packetlength		= $row[11] ? $row[11] : '';
			$dscp				= $row[12] ? $row[12] : '';
			$fragmentencoding	= $row[13] ? $row[13] : '';
			$action				= $row[14] ? $row[14] : '';
			$validfrom			= $row[15] ? $row[15] : '';
			$validto			= $row[16] ? $row[16] : '';

			logit("debug:");
			logit("number of collums in \@row:$#row");
			logit("flowspecruleid: $flowspecruleid - $row[0]");
			logit("direction: $direction - $row[1]");
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
		}
		logit("bye");
		$sth->finish();
		$dbh->disconnect();
	}
	
}

#
# subs below
#

sub mydie(@)
{
	logit(@_);
	exit(0);
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
__DATA__
