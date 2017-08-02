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

use Getopt::Long qw(:config no_ignore_case);

use Sys::Syslog;        # only needed for logit
use POSIX;              # only needed for logit
use Time::Piece;

require '/opt/db2dps/lib/sqlstr.pm';
my $q_withdraw_rule	= 'update flow.flowspecrules set validto=now() where flowspecruleid in ( ${flowspecruleid} );';
my $q_active_rules	= 'select flowspecruleid, destinationprefix, sourceprefix, ipprotocol, destinationport, validto from flow.flowspecrules, flow.fastnetmoninstances where flow.flowspecrules.fastnetmoninstanceid = flow.fastnetmoninstances.fastnetmoninstanceid AND not isexpired AND mode = \'enforce\' order by validto DESC, validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding;';

# prototypes
sub main(@);
sub	logit(@);
sub	parseini();
sub addrule();
sub is_flowspec(@);

# included from version.pm
#INCLUDE_VERSION_PM

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
$action					= "discard";
my ($name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire ) = getpwuid($REAL_USER_ID);
$description			= "cli rule made by user $name/$REAL_USER_ID";

$ttl					= "null";

my $flowspecruleid		= "null";
my $db                  = "";
my $dbuser              = "";
my $dbpass              = "";
my $newrulesdir         = "";
my $allmynetworks		= "";
my $sleep_time			= "";

my $inicfg  = "/opt/db2dps/etc/db.ini";

my $now = strftime "%Y-%m%d %H:%M:%S", localtime(time);

my $isdigit				= qr/^[[:digit:]]+$/x;

my $usage = "
    $0 [-v] add [-h] ... | del ... | print

    print:
        Print active rules with rule id's from database

    del:
	    Set expire time to now for rule matching (list of) rule id(s)

    add:
        --blocktime|b    minutes
        --dst|D          destination: one cidr only (database type limitation)
        --src|S          source:      one cidr only (database type limitation)
        --protocol|P     protocol:    
        --dport|d        destination port
        --sport|s        source port
        --icmp_type|t    icmp type 
        --icmp_code|c    icmp code
        --flags|T        TCP flags
        --length|l       package length
        --dscp|C         DSCP flags
        --frag|f         fragments
        --action|a       action:      accept discard or 'rate-limit 9600'

        IP version 4 addresses only

        flowspec syntax (exabgp) is accepted for all parameters but IP addresses
        e.g.
        Specify http and https only
          -P '=80 =443'
        Specify length: 3 specific all more than 300 or less than 302
          -l '=205 =206 =207 >=300&<=302' 
		 Specify fragments and TCP flags
          -f '[not-a-fragment dont-fragment is-fragment first-fragment last-fragment]'
          -T '[fin syn rst push ack urgent]'

        See exabgp documentation for further explanation.

        WARNING: Only the dest. CIDR is checked, no other parameters. Errors
                 may kill exabgp. Do not annouce nonsence: TCP flags on ICMP
                 or UDP protocols
\n";

# fast zap all active rules:
#
# ddpsrules del `ddpsrules print|awk ' $1 ~ /^[0-9]+$/ { print $1 }'`

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

	if ($ARGV[0] eq '-V')
	{
		print "version:       $version\n";
		print "build date:    $build_date\n";
		print "build_git_sha: $build_git_sha\n";
		print "inicfg:        $inicfg\n";
		print "This version only handles IPv4 by design\n";
		exit 0;
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
		delrule();
	}

	if ($do eq 'print') {
		printrule();
	}
}

sub addrule()
{
	print "addrule: TODO !!!\n";

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

	if ($action =~ m/accept/ || $action =~ m/discard/ || $action =~ m/rate-limit \d\d\d\d/)
	{
		;

	}
	else
	{
			print "action '$action' not accept, discard of rate-limit dddd\n"; exit;
	}

	print<<"EOF";
customerid:            $customerid
uuid:                  $uuid
fastnetmoninstanceid:  $fastnetmoninstanceid
administratorid:       $administratorid
blocktime:             $blocktime
dst:                   $dst
src:                   $src
protocol:              $protocol
sordport:              $sordport
dport:                 $dport
sport:                 $sport
icmp_type:             $icmp_type
icmp_code:             $icmp_code
flags:                 $flags
length:                $length
ttl:                   $ttl
dscp:                  $dscp
frag:                  $frag
action:                $action
description:           $description

Vars with 'null' will not be matched by exabgp

EOF

	print "$customerid,$uuid,$fastnetmoninstanceid,$administratorid,$blocktime,$dst,$src,$protocol,$sordport,$dport,$sport,$icmp_type,$icmp_code,$flags,$length,$ttl,$dscp,$frag,$action,$description\n";
}

sub delrule()
{
	if (@ARGV == 0)
	{
		print "flowspecruleid missing\n${usage}\n" ; exit;
	}
	${flowspecruleid} = join(",", @ARGV);

	my $driver  = "Pg";
	my $sql_query = "update flow.flowspecrules set validto=now() where flowspecruleid in ( ${flowspecruleid} );";

	my $dsn = "DBI:$driver:dbname=$db;host=127.0.0.1;port=5432";
	$dbh = DBI->connect($dsn, $dbuser, $dbpass, { RaiseError => 1 }) or die $DBI::errstr;

	my $sth = $dbh->prepare($sql_query);
	$sth->execute();
	$sth->finish();

	$sql_query = "select flowspecruleid, validto from flow.flowspecrules where flowspecruleid in ( ${flowspecruleid} );";

	$sth = $dbh->prepare($sql_query);
	$sth->execute();

	my $i = 0;
	while (my @row = $sth->fetchrow_array)
	{	
		$i++;
		$flowspecruleid		= $row[0] ? $row[0] : '';
		$validto			= $row[1] ? $row[1] : '';

		my $format = '%Y-%m-%d %H:%M:%S';
		my $expired = substr($validto, 0, -10);
		my $now = strftime "$format", localtime(time);
		my $diff = Time::Piece->strptime($expired, $format) - Time::Piece->strptime($now, $format);

		print "flowspecruleid $flowspecruleid expires at $expired, in $diff seconds\n";

	}
	$sth->finish();
	$dbh->disconnect();

	print "db update freq is $sleep_time seconds\n";
	exit 0;
}

sub printrule()
{
	my $driver  = "Pg";

	my $sql_query = "
		select
		flowspecruleid, direction, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport,
		sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding, action, validfrom,
		validto, description
	from
		flow.flowspecrules,
		flow.fastnetmoninstances
	where
		flow.flowspecrules.fastnetmoninstanceid = flow.fastnetmoninstances.fastnetmoninstanceid
		AND not isexpired
		AND mode = 'enforce'
	order by
		validto DESC,
		validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding ; "; 

	# Connect to the database
	my $dsn = "DBI:$driver:dbname=$db;host=127.0.0.1;port=5432";
	$dbh = DBI->connect($dsn, $dbuser, $dbpass, { RaiseError => 1 }) or die $DBI::errstr;

	my $sth = $dbh->prepare($sql_query);
	$sth->execute();
	print "-" x 133 . "\n"; 
	printf("| %-129s |\n", "Connected to db $db as $dbuser, Active rules");
	print "-" x 133 . "\n"; 
	printf(" %-16s | %-16s | %-16s | %-20s | %-16s | %-30s\n", "flowspecruleid", "dest. prefix", "src. prefix", "ipprotocol", "destinationport", "validto");
	print "-" x 17  . "+" . "-" x 18 . "+" . "-" x 18 . "+" . "-" x 22 . "+" . "-" x 18 . "+" . "-" x 35 . "\n";

	my $i = 0;
	while (my @row = $sth->fetchrow_array)
	{	
		$i++;

		$flowspecruleid = $direction = $destinationprefix = $sourceprefix = $ipprotocol = $srcordestport = $destinationport = $sourceport = $icmptype = $icmpcode = $tcpflags = $packetlength = $dscp = $fragmentencoding = $action = $validfrom = $validto = "";

		$flowspecruleid		= $row[0] ? $row[0] : '';
		$direction			= $row[1] ? $row[1] : '';
		$destinationprefix	= $row[2] ? $row[2] : '@Any';
		$sourceprefix		= $row[3] ? $row[3] : '@Any';
		$ipprotocol			= $row[4] ? $row[4] : '@Any';
		$srcordestport		= $row[5] ? $row[5] : '@Any';
		$destinationport	= $row[6] ? $row[6] : '@Any';
		$sourceport			= $row[7] ? $row[7] : '@Any';
		$icmptype			= $row[8] ? $row[8] : '@Any';
		$icmpcode			= $row[9] ? $row[9] : '@Any';
		$tcpflags			= $row[10] ? $row[10] : '@Any';
		$packetlength		= $row[11] ? $row[11] : '@Any';
		$dscp				= $row[12] ? $row[12] : '@Any';
		$fragmentencoding	= $row[13] ? $row[13] : '@Any';
		$action				= $row[14] ? $row[14] : '@Any';
		$validfrom			= $row[15] ? $row[15] : '';
		$validto			= $row[16] ? $row[16] : '';
		$description		= $row[17] ? $row[17] : '';

		printf(" %-16s | %-16s | %-16s | %-20s | %-16s | %-30s\n", $flowspecruleid, $destinationprefix, $sourceprefix, $ipprotocol, $destinationport, $validto);
	}
	$sth->finish();
	$dbh->disconnect();
	print "Read $i rules\n";
	print "\nSee full announce and withdraw with e.g.: ";
    print "\tsed '/rule:.*12042/!d; s/^.*rule: //; s/[ ]\+/ /g' /var/log/syslog\n\n";
}


# should be in a pm

sub parseini()
{
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
	$sleep_time						= $data{'general'}{'sleep_time'};

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

__DATA__


