#!/usr/bin/perl -w
#
# $Header$
#

#
# Requirements
#
use English;
use FileHandle;
use Getopt::Long qw(:config no_ignore_case);
use Digest::MD5;
use sigtrap qw(die normal-signals);
use NetAddr::IP;
use Net::SSH2;          # ssh v2 access to postgres db
use DBI;                # database

use Sys::Syslog;        # only needed for logit
use POSIX;              # only needed for logit

require '/opt/db2dps/lib/sqlstr.pm';
my $q_withdraw_rule	= 'update flow.flowspecrules set validto=now() where flowspecruleid in ( ${flowspecruleid} );';
my $q_active_rules	= 'select flowspecruleid, destinationprefix, sourceprefix, ipprotocol, destinationport, validto from flow.flowspecrules, flow.fastnetmoninstances where flow.flowspecrules.fastnetmoninstanceid = flow.fastnetmoninstances.fastnetmoninstanceid AND not isexpired AND mode = \'enforce\' order by validto DESC, validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding;';

# prototypes
sub main(@);
sub	logit(@);
sub	parseini();
sub addrule();
sub is_flowspec(@);

#
# Global vars
#

my ($customerid,$uuid,$fastnetmoninstanceid,$administratorid,$blocktime,$dst,$src,$protocol,$sordport,$dport,$sport,$icmp_type,$icmp_code,$flags,$length,$ttl,$dscp,$frag,$action,$description);
# ttl not used
#

my $verbose = 0;
$customerid = 1;

$uuid					= "00:25:90:47:2b:48";
$fastnetmoninstanceid	= "1";
$administratorid		= "42";
$blocktime				= "10";

$dst					= "null";
$src					= "null";
$protocol				= "null";
$sordport				= "null";
$dport					= "null";
$sport					= "null";
$icmp_type				= "null";
$icmp_code				= "null";
$flags					= "null";
$length					= "null";
$dscp					= "null";
$frag					= "null";
$action					= "null";
$description			= "null";

$ttl					= "null";
my $flowspecruleid		= "null";
my $db                  = "";
my $dbuser              = "";
my $dbpass              = "";
my $newrulesdir         = "";
my $allmynetworks		= "";

my $usage = "
    $0 [-v] add ... | del ... | print
    print:
        Print active rules with rule id's from database

    del:
	    Set expire time to now for one rule matching rule id

    add:
        --blocktime|b    minutes
        --dst|D          destination
        --src|S          source
        --protocol|P     protocol
        --dport|d        destination port
        --sport|s        source port
        --icmp_type|t    icmp type 
        --icmp_code|c    icmp code
        --flags|T        TCP flags
        --length|l       package length
        --dscp|C         DSCP flags
        --frag|f         fragments
        --action|a       action

		Syntax is for exabgp; you may use =<> and & for complex expressions
		IP version 4 addresses only
\n";

################################################################################
# main
################################################################################

main();

exit 0;

#
# subs
#
sub main(@) {

	parseini();
	# print"db=$db, dbuser=$dbuser, dbpass=$dbpass, newrulesdir=$newrulesdir\n";

	if (! defined $ARGV[0])
	{
		print "command missing\n${usage}\n" ; exit;
	}

	if ($ARGV[0] eq '-v')
	{
		$verbose = 1;
		shift @ARGV;
	}

	if (! defined $ARGV[0])
	{
		print "command missing\n${usage}\n" ; exit;
	}

	my $do = $ARGV[0];
	shift @ARGV;
	
	if ($do eq 'add')
	{
		if (!GetOptions(
			'blocktime|b=s'		=> \$blocktime,
			'dst|D=s'			=> \$dst,
			'src|S=s'			=> \$src,
			'protocol|P=s'		=> \$protocol,
			'sordport|p=s'		=> \$sordport,
			'dport|d=s'			=> \$dport,
			'sport|s=s'			=> \$sport,
			'icmp_type|t=s'		=> \$icmp_type,
			'icmp_code|c=s'		=> \$icmp_code,
			'flags|T=s'			=> \$flags,
			'length|l=s'		=> \$length,
			'dscp|C=s'			=> \$dscp,
			'frag|f=s'			=> \$frag,
			'action|a=s'		=> \$action
		))
		{
			print $usage;
			exit 0;
		}
		addrule();
	}
	if ($do eq 'del') {
		$flowspecruleid = $ARGV[0];
		if (! defined $flowspecruleid)
		{
			print "flowspecruleid missing\n${usage}\n" ; exit;
		}
		delrule();
	}

	if ($do eq 'print') {
		printrule();
	}

}

sub addrule()
{
	print "addrule\n";

	if (! is_flowspec("flow", $dport))
	{
		print "dstport $dport is not flowspec\n";
		exit 0;
	}

	if($dst eq 'null')
	{
		$dst = $allmynetworks;
    	print "using dst = $dst\n";
	}
	else
	{
		dest_is_our_network();
	}
	print "$customerid,$uuid,$fastnetmoninstanceid,$administratorid,$blocktime,$dst,$src,$protocol,$sordport,$dport,$sport,$icmp_type,$icmp_code,$flags,$length,$ttl,$dscp,$frag,$action,$description\n";
}

sub delrule()
{
	print "delete $flowspecruleid\n";
}

sub printrule()
{
	print "printrule\n";
}


# should be in a  pm

sub parseini()
{
	my $inicfg  = "/opt/db2dps/etc/db.ini";

	open my $fh, '<', $inicfg or mydie("Could not open '$inicfg' $!");

	while (my $line = <$fh>) {
		if ($line =~ /^\s*#/) {
			next;	   # skip comments
		}
		if ($line =~ /^\s*$/) {
			next;	   # skip empty lines
		}

		if ($line =~ /^\[(.*)\]\s*$/) {
			$section = $1;
			next;
		}

		if ($line =~ /^([^=]+?)\s*=\s*(.*?)\s*$/)
		{
			my ($field, $value) = ($1, $2);
			if (not defined $section)
			{
				logit("Error in '$inicfg': Line outside of seciton '$line'");
				next;
			}			$data{$section}{$field} = $value;
		}
	}

    $db                             = $data{'general'}{'dbname'};
    $dbuser                         = $data{'general'}{'dbuser'};
    $dbpass                         = $data{'general'}{'dbpassword'};
    $newrulesdir                    = $data{'general'}{'newrulesdir'};      # dir where new rules are uploaded. P.t. only one dir
	$allmynetworks					= $data{'general'}{'ournetworks'};

}

sub logit(@)
{
	my $msg = join(' ', @_);
	syslog("user|err", "$msg");
	my $now = strftime "%H:%M:%S (%Y/%m/%d)", localtime(time);
	print STDOUT "$now: $msg\n" if ($verbose);
 }

sub mydie(@)
{
    logit(@_);
    exit(0);
}

sub dest_is_our_network()
{
	my $destinationprefix_is_within_my_network = 0;
	foreach my $mynetwork (split ' ', $allmynetworks)
	{
		my $subnet = new NetAddr::IP $mynetwork;
		my $dst_cidr = new NetAddr::IP $dst;
		if ($dst_cidr->within($subnet))
		{
			logit("dst $dst is within $subnet");
			$destinationprefix_is_within_my_network = 1;
		}
	}
	if ($destinationprefix_is_within_my_network == 0)
	{
		print "error: dst $dst is not within any of $allmynetworks\n";
		exit ;
	}
}

sub is_flowspec(@)
{
	# simple check if vars are what they claim
	my ($tmpl, $var) = @_;
	if ($tmpl eq 'flow')
	{
		if ($var =~ m/^[ -=<>&\.0-9]*$/)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	elsif($tmpl eq 'port')
	{
		if(0 <= $var && $var <= 65536)
		{
			return 1;
		}
		return 0;
	}
}
