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
use Fatal qw(open);

#
# prototypes
#
sub main(@);
sub logit(@);
sub mydie(@);

my $driver	= "Pg"; 

#
# Global vars
#

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

my $verbose = 1;

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
	# you've already got your DB handle:
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

	close ($fh);

	logit("database	= $db");
	logit("dbadmin		= $dbuser");

	# Connect to the database
	my $dsn = "DBI:$driver:dbname=$db;host=127.0.0.1;port=5432";
	$dbh = DBI->connect($dsn, $dbuser, $dbpass, { RaiseError => 1 }) or mydie $DBI::errstr;

	# Trace to a file for debugging ..
	$dbh -> trace(1, '/tmp/tracelog.txt');

	logit("database connected successfully");

	my @tables = $dbh->tables();
	#foreach my $table (@tables) {
	foreach my $table ("flow.flowspecrules") {
		logit("table = $table");

		my $sql = "select * from $table";
		my $sth = $dbh->prepare( $sql );

		$sth->execute(); # check for errors, either set RaiseError or have a "die" clause here

		print "Structure of $table \n\n";
		my $num_fields = $sth->{NUM_OF_FIELDS};
		for ( my $i=0; $i< $num_fields; $i++ ) {
			my $field = $sth->{NAME}->[$i];
			my $type = $sth->{TYPE}->[$i];
			my $precision = $sth->{PRECISION}->[$i] ? $sth->{PRECISION}->[$i] : "n/a" ; # e.g. VARCHAR(50) has a precision of 50
			printf("field: %20s\ttype\t%20s\tpressision %10s\n", $field, $type, $precision);
		}
		$sth->finish();
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
