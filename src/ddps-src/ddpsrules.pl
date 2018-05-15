#!/usr/bin/perl -w
#   
#   Copyright 2017, DeiC, Niels Thomas Haugård
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

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
use Sys::Hostname;
use File::Temp qw(tempfile);
use File::Copy;
use File::Basename;
use Term::ANSIColor;
use Term::ReadKey;

use Sys::Syslog;        # only needed for logit
use POSIX;              # only needed for logit
use Time::Piece;

# prototypes
sub main(@);
sub	logit(@);
sub	parseini();
sub addrule();
sub is_flowspec(@);
require '/opt/db2dps/lib/sqlstr.pm';

#
# Global vars
#

my ($customerid,$uuid,$fastnetmoninstanceid,$administratorid,$blocktime,$dst,$src,$protocol,$sordport,$dport,$sport,$icmp_type,$icmp_code,$tcpflags,$length,$ttl,$dscp,$frag,$action,$description);
my $add_description = "";

# my $q_withdraw_rule	= 'update flow.flowspecrules set validto=now() where uuid_flowspecruleid in ( \'${uuid_flowspecruleid}\' );';
# my $q_active_rules	= 'select uuid_flowspecruleid, destinationprefix, sourceprefix, ipprotocol from flow.flowspecrules, flow.fastnetmoninstances where flow.flowspecrules.uuid_fastnetmoninstanceid = flow.fastnetmoninstances.uuid_fastnetmoninstanceid AND not isexpired AND mode = \'enforce\' order by validto DESC, validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding;';

# ttl not used
#

my $verbose = 0;
#$customerid = 1;

$dst					= "null";
$src					= "null";
$protocol				= "null";
$sordport				= "null";
$dport					= "null";
$sport					= "null";
$icmp_type				= "null";
$icmp_code				= "null";
$tcpflags				= "null";
$length					= "null";
$dscp					= "null";
$frag					= "null";
$action					= "discard";
my ($name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire ) = getpwuid($REAL_USER_ID);
$description			= "cli rule made by user $name/$REAL_USER_ID";

$ttl					= "null";

my $uuid_flowspecruleid	= "null";
my $db                  = "";
my $dbuser              = "";
my $dbpass              = "";
my $newrulesdir         = "";
my $allmynetworks		= "";
my $sleep_time			= "";   # daemon update / read interval
my $loop                = 0;
my $sleeptime           = 0;    # default sleep time for $0 active [-s sleeptime]

my $inicfg  = "/opt/db2dps/etc/db.ini";

my $now = strftime "%Y-%m%d %H:%M:%S", localtime(time);

my $isdigit				= qr/^[[:digit:]]+$/x;
my $assume_yes = 0;

my $usage = "
    $0 [-v] add [-h] ... | del ... | active [-s seconds] | log

    active:
        Print active rules with rule id's from database
        -s number
        interactive print active rules in a loop sleeping number seconds

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
        --tcpflags|T     TCP tcpflags
        --length|l       package length
        --dscp|C         DSCP flags
        --frag|f         fragments
        --action|a       action:      accept discard or 'rate-limit 9600'
        --comment|c     comment

        -h               print help on add
        -y               do not prompt before implement the rule

        IP version 4 addresses only

        Please quote all arguments in single quotes ''

        flowspec syntax (exabgp) is accepted for all parameters but IP addresses
        e.g.
        Specify http and https only
          -P '=80 =443'
        Specify length: 3 specific all more than 300 or less than 302
          -l '=205 =206 =207 >=300&<=302' 
        Specify fragments and TCP tcpflags
          -f '[not-a-fragment dont-fragment is-fragment first-fragment last-fragment]'
          -T '[fin syn rst push ack urgent]'

        See exabgp documentation for further explanation.

        WARNING: Only the dest. CIDR is checked, no other parameters. Errors
                 may kill exabgp. Do not annouce nonsence: TCP tcpflags on ICMP
                 or UDP protocols
\n";

################################################################################
#INCLUDE_VERSION_PM
################################################################################

main();

exit 0;

#
# subs
#
sub main(@) {

	parseini();
	# print"db=$db, dbuser=$dbuser, dbpass=$dbpass, newrulesdir=$newrulesdir\n";

	if (! defined $ARGV[0] || $ARGV[0] eq '-h')
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
		if (defined $ARGV[0] && $ARGV[0] eq '-y')
		{
			$assume_yes = 1;
			shift @ARGV;
		}
		if (defined $ARGV[0] && $ARGV[0] eq '-h')
		{
			print "${usage}\n" ; exit;
		}
		if (! defined $ARGV[0])
		{
			print "${usage}\n"; exit ;
		}

		if (!GetOptions(
			'blocktime|b=s'         => \$blocktime,
			'dst|D=s'               => \$dst,
			'src|S=s'               => \$src,
			'protocol|P=s'          => \$protocol,
			'sordport|p=s'          => \$sordport,
			'dport|d=s'             => \$dport,
			'sport|s=s'             => \$sport,
			'icmp_type|t=s'         => \$icmp_type,
			'icmp_code|c=s'         => \$icmp_code,
			'tcpflags|T=s'          => \$tcpflags,
			'length|l=s'            => \$length,
			'dscp|C=s'              => \$dscp,
			'frag|f=s'              => \$frag,
			'action|a=s'            => \$action,
			'explanation|e=s'		=> \$add_description
		))
		{
			print $usage;
			exit 0;
		}
		addrule();
	}elsif ($do eq 'del')
	{
		delrule();
	}
	elsif ($do eq 'active')
	{
        if (defined $ARGV[0] && $ARGV[0] eq '-s')
        {
            if ( defined($ARGV[1]) && ($ARGV[1] =~ m/^\d+$/))
            {
                $sleeptime = $ARGV[1];
            }
            else
            {
                $sleeptime = 4;
            }
        }
        else
        {
            $sleeptime = 0;
        }
		printrule();
	}
	elsif ($do eq 'log')
	{
		my $login = (getpwuid $>);
		die "$0 log must run as root" if $login ne 'root';
		my $hostname = hostname;
		my $syslog = "/var/log/syslog";
		open my $fh, '<', $syslog or die("Could not open '$syslog' $!");

        while (my $line = <$fh>) {
			if ($line =~ m/rule:/)
			{
				#$line =~ s/^.*rule://;
				$line =~ s/$hostname.*rule: //;
				$line =~ tr/ //s;
				print "$line";
			}
		}
	}
	else
	{
		print $usage; exit 0;
	}
}

sub addrule()
{
	my $login = (getpwuid $>);
	die "$0 add must run as root" if $login ne 'root';

	if ($protocol eq 'null')					{ print "please specify protocol (eg =tcp =udp =icmp)\n";	exit 0; }

	if (! is_flowspec("flow", $src))			{ print "src $src is not flowspec\n";						exit 0; }
	if (! is_flowspec("flow", $dst))			{ print "dst $dst is not flowspec\n";						exit 0; }
	if (! is_flowspec("flow", $dport))			{ print "dstport $dport is not flowspec\n";					exit 0; }
	if (! is_flowspec("flow", $sport))			{ print "dstport $dport is not flowspec\n";					exit 0; }

	if (! is_flowspec("protocol", $protocol))	{ print "protocol $protocol is not flowspec\n";				exit 0; }

	if (! is_flowspec("flow", $icmp_code))		{ print "icmp_code $icmp_code is not flowspec\n";			exit 0; }
	if (! is_flowspec("flow", $icmp_type))		{ print "icmp_type $icmp_type is not flowspec\n";			exit 0; }

    if ($add_description ne '')                 { $description = $add_description . "/ made by $name/$REAL_USER_ID"; };

	if ($frag ne 'null')
	{
		for ($frag) {
			s/\[//;
			s/\]//;
		}
		my $tmpstr = $frag;
		for ($tmpstr) {
			s/not-a-fragment//;
			s/dont-fragment//;
			s/is-fragment//;
			s/first-fragment//;
			s/last-fragment//;
			s/\s+//;
		}
		if ($tmpstr ne '') { print "fragmentencoding incorrect: found $tmpstr\n";	exit 0; }

		$frag = "[" . $frag . "]";
	}

	# tcp tcpflags
	# cwr ece urg ack psh rst syn fin

	if ($tcpflags ne 'null')
	{
		for ($tcpflags) {
			s/\[//;
			s/\]//;
		}
		$tmpstr = $tcpflags;
		for ($tmpstr) {
			s/cwr//;
			s/ece//;
			s/urg//;
			s/ack//;
			s/psh//;
			s/rst//;
			s/syn//;
			s/fin//;
		}
		if ($tmpstr ne '') { print "tcp tcpflags incorrect: found $tmpstr\n";	exit 0; }
		$tcpflags = "[" . $tcpflags . "]";
	}

	if ($protocol =~ m/tcp|6/ && ($icmp_type ne 'null' || $icmp_code ne 'null'))
	{
		print "protocol mismatch: $protocol and icmp type/code\n"; exit ;
	}

	if ($protocol !~ /tcp|6/i && $tcpflags ne 'null')
	{
		print "tcpflags $tcpflags require TCP protocol not $protocol\n"; exit;
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


	my $rule_line = "$customerid;$uuid;$fastnetmoninstanceid;$administratorid;$blocktime;$dst;$src;$protocol;$sordport;$dport;$sport;$icmp_type;$icmp_code;$tcpflags;$length;$ttl;$dscp;$frag;$action;$description";

	print<<"EOF";
customerid:            ->$customerid<-
uuid:                  ->$uuid<-
fastnetmoninstanceid:  ->$fastnetmoninstanceid<-
administratorid:       ->$administratorid<-
blocktime:             ->$blocktime<-
dst:                   ->$dst<-
src:                   ->$src<-
protocol:              ->$protocol<-
sordport:              ->$sordport<-
dport:                 ->$dport<-
sport:                 ->$sport<-
icmp_type:             ->$icmp_type<-
icmp_code:             ->$icmp_code<-
tcpflags:              ->$tcpflags<-
length:                ->$length<-
dscp:                  ->$dscp<-
frag:                  ->$frag<-
action:                ->$action<-
description:           ->$description<-

Vars with 'null' are wild charts, and will match anything by exabgp

Rule:
------
$rule_line
------

EOF

	if (${assume_yes} eq 0)
	{
		print "enforce rule ? [no] ";
		my $input = <STDIN>;
		if (${input} !~ m/^[yYjJ].*$/)
		{
			print "Ok, bye\n"; exit 0;
		}
	}

	my $tmp_fh = new File::Temp( UNLINK => 0, TEMPLATE => 'newrules_XXXXXXXX', DIR => '/tmp', SUFFIX => '.dat');

	print $tmp_fh "head;fnm;noop;1;unknown\n";
	print $tmp_fh "$rule_line\n";
	print $tmp_fh "last-line\n";
	close($tmp_fh)||die "close $tmp_fh failed: $!";

	my $basename = basename($tmp_fh);
    #print "$tmp_fh -> $newrulesdir/$basename\n";
	move("$tmp_fh", "$newrulesdir/$basename") || die "move failed: $!";
	print "done\nshow result with\n$0 active or $0 log\n";
}

sub delrule()
{
	if (@ARGV == 0)
	{
		print "flowspecruleid missing\n${usage}\n" ; exit;
	}
    my @purgeid = @ARGV;
    foreach my $id (@purgeid) { $id = "'{$id}'"; }
	${uuid_flowspecruleid} = join(",", @purgeid);

	my $driver  = "Pg";
	my $sql_query = "update flow.flowspecrules set validto=now() where uuid_flowspecruleid in ( ${uuid_flowspecruleid} );";

	my $dsn = "DBI:$driver:dbname=$db;host=127.0.0.1;port=5432";
	$dbh = DBI->connect($dsn, $dbuser, $dbpass, { RaiseError => 1 }) or die $DBI::errstr;

	my $sth = $dbh->prepare($sql_query);
	$sth->execute();
	$sth->finish();

	$sql_query = "select uuid_flowspecruleid, validto from flow.flowspecrules where uuid_flowspecruleid in ( ${uuid_flowspecruleid} );";

	$sth = $dbh->prepare($sql_query);
	$sth->execute();

	my $i = 0;
	while (my @row = $sth->fetchrow_array)
	{	
		$i++;
		$uuid_flowspecruleid		= $row[0] ? $row[0] : '';
		$validto			        = $row[1] ? $row[1] : '';

		my $format = '%Y-%m-%d %H:%M:%S';
		my $expired = substr($validto, 0, -10);
		my $now = strftime "$format", localtime(time);
		my $diff = Time::Piece->strptime($expired, $format) - Time::Piece->strptime($now, $format);

		print "flowspecruleid $uuid_flowspecruleid expires at $expired, in $diff seconds\n";

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
		select distinct uuid_flowspecruleid
		uuid_flowspecruleid, direction, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport,
		sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding, action, validfrom,
		validto, description
	from
		flow.flowspecrules,
		flow.fastnetmoninstances
	where
		 not isexpired
	order by
		validto DESC,
		validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding ;"; 

	# Connect to the database
	my $dsn = "DBI:$driver:dbname=$db;host=127.0.0.1;port=5432";
	$dbh = DBI->connect($dsn, $dbuser, $dbpass, { RaiseError => 1 }) or die $DBI::errstr;

    while (1)
    {

        my $sth = $dbh->prepare($sql_query);
        $sth->execute();

        if( $sleeptime ne 0) {
            print "\033[2J";    #clear the screen
            print "\033[0;0H"; #jump to 0,0
        }

        my ($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();
        if ($wchar lt 154) 
        {
            print "Please set terminal width to 154 or greater\n";
            exit 0;
        }
        my $c;

        my $now = strftime "%H:%M:%S (%Y/%m/%d)", localtime(time);
        print color('bright_white on_grey10') if( $sleeptime ne 0);
        print "-" x $wchar . "\n"; 
        $c = $wchar - 35;
        printf("| %-${c}s %30s |\n", "Connected to db $db as $dbuser, Active rules", "$now" );
        print "-" x $wchar . "\n"; 
        $c = $wchar - 124 ; # 38 20 20 22 18 
        printf(" %-36s | %-18s | %-18s | %-20s | %-16s | %-${c}s\n", "flowspecruleid", "dest. prefix", "src. prefix", "ipprotocol", "destinationport", "validto");
        $c = $wchar - 123 ;
        print "-" x 38  . "+" . "-" x 20 . "+" . "-" x 20 . "+" . "-" x 22 . "+" . "-" x 18 . "+" . "-" x ${c} . "\n";
        print color('reset') if( $sleeptime ne 0);

        my $i = 0;
        while (my @row = $sth->fetchrow_array)
        {	
            $i++;

            $uuid_flowspecruleid = $direction = $destinationprefix = $sourceprefix = $ipprotocol = $srcordestport = $destinationport = $sourceport = $icmptype = $icmpcode = $tcpflags = $packetlength = $dscp = $fragmentencoding = $action = $validfrom = $validto = "";

            $uuid_flowspecruleid		= $row[0] ? $row[0] : '';
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

            if ($sourceprefix	eq '0.0.0.0/0')
            {
                $sourceprefix = '@Any';
            }

            if( $sleeptime ne 0) 
            {
                if ($i % 2)
                {
                    print color('black on_grey23');
                }
                else
                {
                    print color('black on_grey15');
                }
            }

            $c = $wchar - 124 ;
            printf(" %-36s | %-18s | %-18s | %-20s | %-16s | %-${c}s\n", $uuid_flowspecruleid, $destinationprefix, $sourceprefix, $ipprotocol, $destinationport, $validto);
            print color('reset') if( $sleeptime ne 0);

        }
        $sth->finish();
	    print "Read $i rules - see full rules with sudo ddpsrules log\n\n";
        if( $sleeptime eq 0)
        {
	        $dbh->disconnect();
            exit 0;
        }
        sleep $sleeptime;
    }
	$dbh->disconnect();
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

	$uuid							= $data{'ddpsrules'}{'uuid'};
	$customerid						= $data{'ddpsrules'}{'customerid'};
	$fastnetmoninstanceid			= $data{'ddpsrules'}{'fastnetmoninstanceid'};
	$administratorid				= $data{'ddpsrules'}{'administratorid'};
	$blocktime						= $data{'ddpsrules'}{'blocktime'};

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
	if($var eq 'null')
	{
		return 1;
	}
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
	elsif($tmpl eq 'digit')
	{
		if ($var =~ m/^[[:digit:]]+$/)
		{
			return 1;
		}
		return 0;
	}
	elsif($tmpl eq 'protocol')
	{
		if ($var =~ m/^[ -=<>&\.0-9a-z]*$/)
		{
			return 1;
		}
		return 0;
	}

}
