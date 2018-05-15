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
#   query(set isexpired = TRUE and isactivated = FALSE for withdrawn rules in database)
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
#       sudo apt-get install libnet-openssh-compat-perl liblist-moreutils-perl
#       apt-get install libnet-openssh-compat-perl
#       apt-get -y install libnet-ssh2-perl libproc-daemon-perl
#       apt -y install libnetaddr-ip-perl libtypes-path-tiny-perl
#

#
# Requirements
#
use strict;
use warnings;
use 5.14.0;             # say, switch etc.
use sigtrap qw(die normal-signals);
use DBI;                # database

use Sys::Syslog;        # only needed for logit
use POSIX;              # only needed for logit
use Getopt::Long qw(:config no_ignore_case);
use Net::OpenSSH;
use List::MoreUtils qw(uniq);
use Proc::Daemon;
use Socket qw( inet_aton );
use NetAddr::IP;
use Path::Tiny;
use File::stat;
use File::Temp qw(tempfile);
use IO::Socket::INET;
use Sys::Hostname;


require '/opt/db2dps/lib/sqlstr.pm';

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
sub moverulestomaster();
sub processnewrules();
sub getlocalipv4addr();

# URL's with useful information
# http://www.microhowto.info/howto/connect_to_a_postgresql_database_using_perl_dbi.html
# https://www.tutorialspoint.com/postgresql/postgresql_perl.htm
# http://www.techrepublic.com/article/retrieve-data-from-a-postgresql-database-using-the-perl-dbi/
# https://www.compose.com/articles/connecting-and-loading-data-to-postgresql-with-perl/
# https://www.postgresql.org/docs/9.3/static/plperl.html
# http://www.easysoft.com/developer/languages/perl/dbd_odbc_tutorial_part_2.html
# http://search.cpan.org/~timb/DBI-1.636/DBI.pm


#
# Global vars
#
my $driver  = "Pg"; 
my $usage = "\n$0 -s seconds [-v | -d ] \n";

my $flowstrmatch = qr/[=<>& ][\.0-9\/]*/;       # matches ports, length and ipv4 addresses as flowspec expressions
my $isdigit     = qr/^[[:digit:]]+$/x;          # Calling POSIX::isdigit() is deprecated in Perl 5.20, and removed in Perl 5.24

my $verbose = "";
my $sleeptime = 10;
my $rundaemon = 0;
my $continue = 1;

#INCLUDE_VERSION_PM
my $show_version = 0;

my $logfile = "/opt/db2dps/tmp/" . "logfile.txt";       # no longer used
my $inicfg  = "/opt/db2dps/etc/db.ini";

my @implemented_flowspecruleid;

# All BGP rule values
my ($flowspecruleid, $direction, $destinationprefix, $sourceprefix,
        $ipprotocol, $srcordestport, $destinationport, $sourceport, $icmptype,
        $icmpcode, $tcpflags, $packetlength, $dscp, $fragmentencoding
    );

my $sql_query = "";

our $addrule;
our $all_rules;
our $newrules;
our $remove_expired_rules;
our $update_rules_when_announced;
our $update_rules_when_expired;
our $check_admin_rights_on_dst;

my $section;
my %data;
my $db                          = "";
my $rulebase                    = "";
my $dbuser                      = "";
my $dbpass                      = "";
my $clustermembers              = "";
my $localipv4addr               = "";
my $remotemember                = "";

my $allmynetworks               = "";
my $newrulesdir                 = "";
my $hostlist                    = "";
my $datadir                     = "";
my $shutdown                    = "";
my $tcpudpdrop                  = "";
my $icmpdrop                    = "";
my $ipdrop                      = "";
my $blackhole                   = "";
my $ratelimit                   = "";
my $action                      = "";
my $validfrom                   = "";
my $validto                     = "";
my $description                 = "";

my $dbh;
my @unique_implemented_flowspecruleid;

my $at_least_one_successfull_upload = 0;        # Keep track on if upload of the rulebase fails for *all* exabgp hosts

# only connect to exabgp if it is running, check start-time (date string), initialize
my %exabgp_lstart = ();
my $ok_to_connect = 0;
my $exabgp_restarted = 0;


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
        'inicfg|f=s'        => \$inicfg,
        'sleeptime|s=s'     => \$sleeptime,
        'verbose|v'         => \$verbose,
        'daemonize|d'       => \$rundaemon,
        'show_version|V'    => \$show_version
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

    logit("verbose      = $verbose");
    logit("daemonize    = $rundaemon");
    logit("sleeptime    = $sleeptime");
    
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
            next;       # skip comments
        }
        if ($line =~ /^\s*$/) {
            next;       # skip empty lines
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

    $db                             = $data{'general'}{'dbname'};
    $rulebase                       = $data{'general'}{'rulebase'};
    $dbuser                         = $data{'general'}{'dbuser'};
    $dbpass                         = $data{'general'}{'dbpassword'};
    $clustermembers                 = $data{'general'}{'clustermembers'};

    $newrulesdir                    = $data{'general'}{'newrulesdir'};      # dir where new rules are uploaded. P.t. only one dir

    $hostlist                       = $data{'general'}{'hostlist'};
    $datadir                        = $data{'general'}{'datadir'};
    $shutdown                       = $data{'general'}{'shutdown'};
    $tcpudpdrop                     = $data{'general'}{'tcpudpdrop'};
    $icmpdrop                       = $data{'general'}{'icmpdrop'};
    $ipdrop                         = $data{'general'}{'ipdrop'};
    $blackhole                      = $data{'general'}{'blackhole'};
    $ratelimit                      = $data{'general'}{'ratelimit'};

    # my $uuid  = $data{'globals'}{'uuid'} . "-" . $data{'globals'}{'customer'};

    close ($fh);

    $localipv4addr = getlocalipv4addr();
    my $host = hostname();

    logit("database = $db");
    logit("dbadmin  = $dbuser");
    logit("clustermembers = $clustermembers");
    logit("localipv4addr = $localipv4addr");

    # pgpoop2 - two or more members or one only if not using pgpoop2
    $remotemember = $clustermembers;
    for ($remotemember) {
        s/$localipv4addr//;
        s/$host//;
        s/\s+//g;
    };

    # https://stackoverflow.com/questions/6063605/whats-the-fastest-way-to-count-the-number-of-words-in-a-string-in-perl
    my $num;
    $num++ while $remotemember =~ /\S+/g;
    if ($num gt 1)
    {
        die ("configuration error: $clustermembers - only 2 allowed");
    }
    logit("my hostname: $host, second cluster node = $remotemember");

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

    loop: while ($continue)
    {
        if (-e $shutdown)
        {
            logit("shutdown file $shutdown found, exiting");
            unlink $shutdown;
            $dbh->disconnect();
            exit(0);
        }

        logit("quering for recovery mode / test if passive or active db");
        $sql_query = "select pg_is_in_recovery();";
        # https://github.com/DataDog/dd-agent/issues/1182
        # node is in active replication state is to evaluate whether the
        # node is in "recovery mode" - a state in which streaming replicas
        # are persistently in until they are promoted to accept writes from
        # anyone other than their replication master.
        # Once a replica is promoted to master, the call to
        # pg_is_in_recovery will return false without any config changes or
        # server restarts.
        my $sth = $dbh->prepare($sql_query);
        $sth->execute();
        my @tmparr;
        while (my @row = $sth->fetchrow_array)
        {
            if ($row[0] eq 1) {
                logit("db is passive / in recovery mode");
                # check rulefiles, if any send to master
                moverulestomaster();
                sleep $sleeptime;

            } elsif ($row[0] eq 0) {
                logit("db is master / not in recovery mode");
                last loop;
            }

        }
    }

    $allmynetworks = $data{'general'}{'ournetworks'};
    logit("All allowed destination networks: $allmynetworks");

    my $first_loop = 1;

    # only connect to exabgp if it is running, check start-time (date string), initialize
    foreach my $host (split(' ', $hostlist))
    {
        $exabgp_lstart{$host} = "init";
    }

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
            foreach my $id (@implemented_flowspecruleid) { $id = "'{$id}'"; }

            my $unique_implemented_flowspecruleid = join(', ', @implemented_flowspecruleid);
            # !!!!!!!! TODO TODO 
            # ... TRUE where uuid_flowspecruleid in ( 708df52c-2f8d-463d-8e75-b73e38bb2a94, ...
            # fails, must be
            # ... TRUE where uuid_flowspecruleid in ( '{708df52c-2f8d-463d-8e75-b73e38bb2a94}', ...

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
            logit("expiring $#unique_implemented_flowspecruleid rules in db");
            foreach my $id (@implemented_flowspecruleid) { $id = "'{$id}'"; }
            logit("query below, ids: @unique_implemented_flowspecruleid");
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
    { return if (join('.', @quad) !~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) } # prevent non digits from messing up next line
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
    return if $ip =~ /z.*z/;    # multiple omits illegal
 
    my $v4 = '';
    my $len = 8;

    if ($ip =~ s/:((?:\d+\.){3}\d+)$//) {
        # hybrid 4/6 ip
        ($v4) = parse_v4($1)    or return;
        $len -= 2;

    }
    # what's left should be v6 only
    return unless $ip =~ /^[:a-fz\d]+$/i;

    my @h = split(/:/, $ip);
    return if @h + $omits > $len;   # too many segments

    @h = map( $_ eq 'z' ? (0) x ($len - @h + 1) : ($_), @h);
    return join('' => map(sprintf("%04x", hex($_)), @h)).$v4;
}

sub parse_ip($) {
    my $str = shift;
    $str =~ s/^\s*//;
    $str =~ s/\s*$//;

    if ($str =~ s/^((?:\d+\.)+\d+)(?::(\d+))?$//)
    {
        return 'v4', parse_v4($1, $2);
    }

    my ($ip, $port);
    if ($str =~ /^\[(.*?)\]:(\d+)$/) {
        $port = $2;
        $ip = parse_v6($1);
    }
    else
    {
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

    logit("TYPE: $type, hostlist: $hostlist");

    # announce new or all rules
    # For each bgp-host do
    my @hostlist = split(' ', $hostlist);

    foreach my $host (@hostlist)
    {
        my $sshuser         = $data{$host}{'sshuser'};          $sshuser =~ tr/\"//d;
        my $identity_file   = $data{$host}{'identity_file'};    $identity_file =~ tr/\"//d;
        my $public_key      = $data{$host}{'public_key'};       $public_key =~ tr/\"//d;
        my $filtertype      = $data{$host}{'filtertype'};       $filtertype =~ tr/\"//d;
        my $exabgp_pipe     = $data{$host}{'exabgp_pipe'};      $exabgp_pipe =~ tr/\"//d;

        my ($pid, $out, $rin, $rout, $err, $in, $pty);

        my $timeout = 10;
        my %ssh_opts = (user => $sshuser, key_path => $identity_file, timeout => $timeout);

        my $ssh = Net::OpenSSH->new($host, %ssh_opts);
        if ($ssh->error) {
            logit("ssh connection to '$host' failed");
            $ok_to_connect = 0;
        }
        else {
            #
            # host up and accepts connections
            #
            # Get PID of process exabgp (ps) remove blanks (tr) and get start time in seconds (stat)
            #my $cmd = "stat -c%X /proc/`ps -C exabgp -o pid=|tr -d ' '`";
            # Use GNU date to calculate start time in seconds
            #my $cmd = 'echo $(export TZ=UTC0 LC_ALL=C; date -d "$(ps -o lstart= -C exabgp )" +%s)'

            # get start time of exabgp process as a text string, if it changes then do something
            # as new processes do not start earlier than old ones
            my $cmd = '/bin/ps -C exabgp -o pid= >/dev/null && echo $(export TZ=UTC0 LC_ALL=C; date -d "$(ps -o lstart= -C exabgp )" +%s)';

            ($out, $err) = $ssh->capture2($cmd);
            if ($ssh->error) {
                my $msg = "";
                if    ($? == -1) { warn "Failed to execute -- " }
                elsif ($? & 127) {
                    $msg = sprintf("\tChild died with signal %d, %s coredump -- ",
                        ($? & 127),  ($? & 128) ? 'with' : 'without');
                } else {
                    $msg = sprintf("\tChild exited with value %d -- ", $? >> 8);
                    # cmd is ps ... && date ..., as ps fails the whole command fails and exit is 1
                }
                $ok_to_connect = 0;
                logit("$host: service exabgp not running");
            }
            chomp($out); chomp($err);

            if ($out eq '') {
                logit("$host: service exabgp down");
                $ok_to_connect = 0;
            }
            else {
                if ($exabgp_lstart{$host} eq $out) {
                    logit("$host: service exabgp running ok");
                    # $sql_query = $newrules;
                    $ok_to_connect = 1;
                    $exabgp_restarted = 0;
                } 
                else {
                    logit("$host: service exabgp restarted: '$exabgp_lstart{$host}' != '$out'");
                    $exabgp_lstart{$host} = "$out";
                    # $sql_query = $all_rules;
                    $ok_to_connect = 1;
                    $exabgp_restarted = 1;
                }
            } # service exabgp running ok
        } # host up and accepts connections

        if ($ok_to_connect == 1)
        {
            if ($type eq lc "announce")
            {
                # if [ a full feed is required ]
                # only relevant for announcements
                
                if ($exabgp_restarted == 1)
                {
                    logit("querying for all rules");
                    $sql_query = $all_rules;
                }
                {
                    $sql_query = $newrules;
                }
            }
            elsif($type eq lc "withdraw")
            {
                $sql_query = $remove_expired_rules;
            }
            else
            {
                mydie("argument type to mkrulebase must be 'announce' or 'withdraw' not '$type'");
            }

            my $sth = $dbh->prepare($sql_query);
            $sth->execute();

            # print rules to rulebase
            open (my $fh, '>', $rulebase) || mydie "open write '$rulebase' failed: $!";

            # http://www.perlmonks.org/?node_id=312625
            # $sth->execute();
            # my $count = 0;
            # while (my $row = $sth->fetchrow_arrayref()) {
            #   process_row($row);
            #   $count++;
            # }
            # unless ($count) {
            #   do_something_else();
            # }
            #

            while (my @row = $sth->fetchrow_array)
            {   
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
                $validfrom          = $row[15] ? $row[15] : '';     # 2017-02-19 23:04:30.682073+01
                $validto            = $row[16] ? $row[16] : '';     # 2017-02-19 23:04:30.682073+01
                                                                    # Time::HiRes only have this 
                                                                    # xxxx-xx-xx-xx:xx:xx.xxx
                                                                    # so valid* must be truncated

                # Prevent incomplete rules from entering the flow: if an required field fails
                # set $ipprotocol to unknown ('')
                $flowspecruleid         = $flowspecruleid       ? $flowspecruleid       : "";
                $direction              = $direction            ? $direction            : "";
                $destinationprefix      = $destinationprefix    ? $destinationprefix    : "";
                $sourceprefix           = $sourceprefix         ? $sourceprefix         : "";
                $ipprotocol             = $ipprotocol           ? $ipprotocol           : "";
                $srcordestport          = $srcordestport        ? $srcordestport        : "";
                $destinationport        = $destinationport      ? $destinationport      : "";
                $sourceport             = $sourceport           ? $sourceport           : "";
                $icmptype               = $icmptype             ? $icmptype             : "";
                $icmpcode               = $icmpcode             ? $icmpcode             : "";
                $tcpflags               = $tcpflags             ? $tcpflags             : "";
                $packetlength           = $packetlength         ? $packetlength         : "";
                $dscp                   = $dscp                 ? $dscp                 : "";
                $fragmentencoding       = $fragmentencoding     ? $fragmentencoding     : "";
                $action                 = $action               ? $action               : "discard";
                $validfrom              = $validfrom            ? $validfrom            : "";
                $validto                = $validto              ? $validto              : "";

#                logit("debug:");
#                logit("number of collums in \@row:$#row");
#                logit("flowspecruleid: $flowspecruleid");
#                logit("direction: $direction");
#                logit("destinationprefix: $destinationprefix");
#                logit("sourceprefix: $sourceprefix");
#                logit("ipprotocol: $ipprotocol");
#                logit("srcordestport: $srcordestport");
#                logit("destinationport: $destinationport");
#                logit("sourceport: $sourceport");
#                logit("icmptype: $icmptype");
#                logit("icmpcode: $icmpcode");
#                logit("tcpflags: $tcpflags");
#                logit("packetlength: $packetlength");
#                logit("dscp: $dscp");
#                logit("fragmentencoding: $fragmentencoding");
#                logit("action: $action");
#                logit("validfrom: $validfrom");
#                logit("validto: $validto");

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

                # Last line of defence to prevent wron announcements: Do not
                # announce / withdraw networks outside our constituency
                my $dst_subnet = new NetAddr::IP->new($destinationprefix);

                my $destinationprefix_is_within_my_network = 1;

                logit ("testing $destinationprefix = $dst_subnet within my networks: $destinationprefix_is_within_my_network");
                foreach my $mynetwork (split ' ', $allmynetworks)
                {
                    my $subnet = new NetAddr::IP->new($mynetwork);
                    if ($dst_subnet->within($subnet))
                    {
                            logit("dst $dst_subnet is within $subnet");
                            $destinationprefix_is_within_my_network = 0;
                    }
                    else 
                    {
                            logit("dst $dst_subnet is not part of $subnet");
                    }
                }
                logit ("test done destinationprefix_is_within_my_network: $destinationprefix_is_within_my_network (0 is good)");
                if ($destinationprefix_is_within_my_network == 1)
                {
                    logit("program error: rule should be ignored, outside our constituency destinationprefix=$destinationprefix sourceprefix=$sourceprefix ipprotocol=$ipprotocol validfrom=$validfrom validto=$validto");
                    # set expiretime to now for rule and change comment to rule ignored source is ourside our network
                }
                else
                {
                    # The prev. rule -- ignored the on first rule
                    my   (  $prev_flowspecruleid, $prev_direction, $prev_destinationprefix,
                            $prev_sourceprefix, $prev_ipprotocol, $prev_srcordestport,
                            $prev_destinationport, $prev_sourceport, $prev_icmptype,
                            $prev_icmpcode, $prev_tcpflags, $prev_packetlength,
                            $prev_dscp, $prev_fragmentencoding, $prev_validfrom, $prev_validto
                        );

                    # preserve implemented_flowspecruleid - duplicates will be removed later
                    push(@implemented_flowspecruleid, $flowspecruleid);

                    my $filtertype = $data{$host}{'filtertype'};        $filtertype =~ tr/\"//d;
                    if ($filtertype eq lc 'flowspec')
                    {
                        my $rule = "";

                        if (length $sourceprefix)       { $sourceprefix         = "source "             . $sourceprefix         . ";" }
                        if (length $destinationprefix)  { $destinationprefix    = "destination "        . $destinationprefix    . ";" }
                        if (length $sourceport)         { $sourceport           = "source-port "        . $sourceport           . ";" }
                        if (length $destinationport)    { $destinationport      = "destination-port "   . $destinationport      . ";" }
                        if (length $ipprotocol)         { $ipprotocol           = "protocol "           . $ipprotocol           . ";" }
                        if (length $tcpflags)           { $tcpflags             = "tcp-flags "          . $tcpflags             . ";" }
                        if (length $packetlength)       { $packetlength         = "packet-length "      . $packetlength         . ";" }
                        if (length $fragmentencoding)   { $fragmentencoding     = "fragment "           . $fragmentencoding     . ";" }
                        if (length $srcordestport)      { $srcordestport        = "srcordestport "      . $srcordestport        . ";" }
                        if (length $icmptype)           { $icmptype             = "icmptype "           . $icmptype             . ";" }
                        if (length $icmpcode)           { $icmpcode             = "icmpcode "           . $icmpcode             . ";" }
                        if (length $dscp)               { $dscp                 = "dscp "               . $dscp                 . ";" }

                        if ($ipprotocol  !~ /(icmp|tcp|udp|1|6|17)/)            # remove any tcp/udp/icmp specific things, if any
                        {
                            $tcpflags           = "";
                            $icmptype           = "";
                            $srcordestport      = "";
                            $sourceport         = "";
                            $destinationport    = "";
                            $fragmentencoding   = "";
                        }

                        if ($ipprotocol =~ /icmp/)                      # remove any tcp/udp specific things, if any
                        {
                            $destinationport    = "";
                            $sourceport         = "";
                            $tcpflags           = "";
                        }

                        if ($ipprotocol =~ /udp/)                       # remove any tcp/icmp specific things, if any
                        {
                            $tcpflags           = "";
                            $icmptype           = "";
                            $icmpcode           = "";
                        }
                        if ($ipprotocol     =~/null/)                   # may be set to null from the command line tool meaning discard
                        {
                            $ipprotocol         = "";
                            $tcpflags           = "";
                            $icmptype           = "";
                            $tcpflags           = "";
                        }

                        # The syntax for $sourceport and $destinationport is one of
                        #   $destinationport    = "=22 =80 =443";   # ok
                        #   $destinationport    = "=0-19";          # ok but do not mix
                        #   $destinationport    = "<19";            # ok
                        #   $destinationport    = "<19 >1024";      # ok
                        #   $destinationport    = "<19 =22 >1024";  # ok
                        # 1) number between 0,65535     => =$destinationport
                        # 2) list of numbers 0,65535    => =$d =$d =$d ...
                        # 3) [ -<>=][0-9]+              => trust the gui and dont change anything
                        if ($destinationport    =~ /^\d+$/)         # single port number
                        {
                            $destinationport    =~ s/^/=/;
                        }
                        elsif ($destinationport =~ /^[\d\s]+$/)     # list of port number
                        {
                            $destinationport    =~ s/^/=/;
                            $destinationport    =~ s/\s+/ =/g;
                        }
                        if ($destinationport        =~/null/)           # may be set to null from the command line tool meaning discard
                        {
                            $destinationport        = "" ;
                        }

                        if ($sourceport         =~ /^\d+$/)         # single port number
                        {
                            $sourceport         =~ s/^/=/;
                            $sourceport         =~ s/\s+/ =/g;
                        }
                        elsif ($sourceport      =~ /^[\d\s]+$/)     # list of port numbers
                        {
                            $sourceport         =~ s/^/=/;
                            $sourceport         =~ s/\s+/ =/g;
                        }
                        if ($sourceport     =~/null/)           # may be set to null from the command line tool meaning discard
                        {
                            $sourceport     = "" ;
                        }

                        if ($srcordestport      =~ /^\d+$/)         # single port number
                        {
                            $srcordestport      =~ s/^/=/;
                            $srcordestport      =~ s/\s+/ =/g;
                        }
                        elsif ($srcordestport   =~ /^[\d\s]+$/)     # list of port numbers
                        {
                            $srcordestport      =~ s/^/=/;
                            $srcordestport      =~ s/\s+/ =/g;
                        }
                        if ($srcordestport      =~/null/)           # may be set to null from the command line tool meaning discard
                        {
                            $srcordestport      = "" ;
                        }

                        # packet size(s): null, number, list of numbers
                        # or prepositioned <, > or range - -- in that case do nothing and trust the GUI
                        if ($packetlength       =~ /^\d+$/)         # single size
                        {
                            $packetlength       =~ s/^/=/;
                            $packetlength       =~ s/\s+/ =/g;
                        }
                        elsif ($packetlength    =~ /^[\d\s]+$/)     # list of sizes
                        {
                            $packetlength       =~ s/^/=/;
                            $packetlength       =~ s/\s+/ =/g;
                        }
                        if ($packetlength       =~/null/)           # may be set to null from the command line tool meaning discard
                        {
                            $packetlength       = "" ;
                        }

                        # final rule
                        $rule = "$type flow route $flowspecruleid { match { $sourceprefix $destinationprefix $sourceport $destinationport $ipprotocol $tcpflags $icmptype $icmpcode $packetlength $fragmentencoding $dscp } then { $action } } }";
                        # removed '$srcordestport' -- pester exabgp!? 
                        # $rule = "$type  ... match ... $srcordestport ...
                        logit("rule: $rule");
                        print $fh "$rule\n";
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
            }
            close $fh;      # rulebase

            logit("rulebase: $rulebase, size: ",  stat($rulebase)->size);

            $sth->finish();

            # send $rulebase to $host:exabgp_pipe if we have any rules
            # This implementation may block everything if the scp transfer hangs
            # Fix - in C - with https://www.libssh2.org/examples/sftp_write_sliding.html
            # have AMD fix exabgp so we can scp to the pipe again or see
            # https://gist.github.com/melo/2829330
            # to do an scp (r, tmpfile) ; exec(sudo cat tmpfile > ....)
            #
            # TODO: Preserve rulebase if we cannot connet to at least one BGP host and try later
            # Move to global and don't exipre if = 0;
            # my $at_least_one_successfull_upload = 0;
            $at_least_one_successfull_upload = 0;

            my @unique_implemented_flowspecruleid = uniq @implemented_flowspecruleid;
            if ($#unique_implemented_flowspecruleid >= 0)
            {
                my $i = $#unique_implemented_flowspecruleid + 1;
                logit("sending $i rules to $host");

                my ($pid, $out, $rin, $rout, $err, $in, $pty);

                my $timeout = 10;
                my %ssh_opts = (user => $sshuser, key_path => $identity_file, timeout => $timeout);

                my $ssh = Net::OpenSSH->new($host, %ssh_opts);
                if ($ssh->error) {
                    logit("ssh/scp connection to '$host' failed");
                    $ok_to_connect = 0;
                }

                if ($ssh->scp_put($rulebase, $exabgp_pipe))
                {
                    logit("succesfully transfered $type $rulebase to $host:$exabgp_pipe");
                    $at_least_one_successfull_upload = 1;
                }
                else
                {
                    logit("failed transfer $type $rulebase to $host:$exabgp_pipe: $!");
                }
            }
            else
            {
                logit("no $type rules: update $host not needed");
            }
        } # ok to connect ...
        else
        {
            logit("$host: host or service down");
        }
    } # end for each host in hostlist announce ...
}

sub moverulestomaster()
{
    my @rulefiles = ();
    opendir (DIR, $newrulesdir) or mydie "Could not open '$newrulesdir' $!";
    while ( my $node = readdir(DIR) )
    {
        next if ($node =~ /^\./);
        push (@rulefiles, $node);
    }
    closedir DIR;
    my $i = $#rulefiles + 1;
    logit("found $i files in '$newrulesdir'");
    my $sshuser         = $data{$remotemember}{'sshuser'};          $sshuser =~ tr/\"//d;
    my $identity_file   = $data{$remotemember}{'identity_file'};    $identity_file =~ tr/\"//d;
    my $public_key      = $data{$remotemember}{'public_key'};       $public_key =~ tr/\"//d;

    logit("remotemember: '$remotemember', '$sshuser', $identity_file");
    my ($pid, $out, $rin, $rout, $err, $in, $pty);

    my $timeout = 10;
    my %ssh_opts = (user => $sshuser, key_path => $identity_file, timeout => $timeout);

    my $ssh = Net::OpenSSH->new($remotemember, %ssh_opts);
    if ($ssh->error) {
        logit("ssh/scp connection to '$remotemember' failed");
        $ok_to_connect = 0;
    }
    else {
        foreach my $r (@rulefiles)
        {
            my $file    = path($newrulesdir . "/" . $r);
            if ($ssh->scp_put("$file", "/tmp")) {
                unlink $file or logit("Could not unlink $file: $!");
            }
            else {
                 logit("scp failed: $!");
            }
        }
    }
}

sub processnewrules()
{
    # Check for new rules. Read all rule files except those
    # not ending with "last-line"
    # sort rules and add to database && delete rulefiles || warn

    my @rulefiles = ();
    my $file_finished_ok_string = "last-line";
    my $document;
    opendir (DIR, $newrulesdir) or mydie "Could not open '$newrulesdir' $!";
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
        my %src_topports    = ();
        my %toplengths      = ();
        my $n = 0;

        my $file_finished_ok_string = "last-line";

        my $file    = path($newrulesdir . "/" . $r);
        my $head; my $tail; my $type; my $optimize, my $version; my $attack_info;

        my $tmp;
        ($head) = $file->lines( {count =>  1}); chomp($head);
        ($tail) = $file->lines( {count => -1}); chomp($tail);

        ($tmp, $type, $optimize, $version, $attack_info) = split(';', $head);
        chomp($attack_info);

        my @lines = $file->lines_utf8;

        my $fragment_type = 0;
        my %tcp_flags   = ();

        # https://doc.pfsense.org/index.php/What_are_TCP_Flags
        foreach (split(/ /, "cwr ece urg ack psh rst syn fin"))
        {
            $tcp_flags{$_} = 0;
        }

        my ($action,$customerid,$uuid,$fastnetmoninstanceid,$uuid_administratorid,$blocktime,$dst,$src,$protocol,$sport,$dport,$icmp_type,$icmp_code,$flags,$length,$ttl,$dscp,$frag,$description);
        my $length_min  = 90000;    # jumbo package: count down
        my $length_max  = 0;        # max = 0: increment

        my $dst_prev    = "";
        my $dst_uniq    = 1;        # assume only one source

        my $src_prev    = "";
        my $src_uniq    = 1;        # assume only one source is targeting us


        my $sport_min   = 65536;    # minimum port number is max value (2^16) - decrement
        my $sport_max   = 0;

        my $dport_min   = 65536;    # initialize to max value - decrement real min value
        my $dport_max   = 0;        # initialize to min value - increment real max value


        if ($head !~ /head/)                        { logit("$file NOT ok: missing head");                      next;}
        if ($tail !~ /$file_finished_ok_string/)    { logit("$file NOT ok: missing $file_finished_ok_string");  next;}
        if ($#lines < 2)                            { logit("$file NOT ok: lines $#lines < 2");                 next;}

        my $rules_in_file = $#lines - 1; # base 0, subtract header/footer
        logit("$file ok type=$type optimize=$optimize ver=$version attack_info=$attack_info lines=$#lines");

        # process rules and add to database
        if ($optimize eq lc "doop" || $optimize eq lc "opop")
        {
            foreach my $line (@lines)
            {
                next if ($line =~ m/^head/);
                next if ($line =~ m/$file_finished_ok_string/);
                chomp($line);
                ($customerid,$uuid,$fastnetmoninstanceid,$uuid_administratorid,$blocktime,$dst,$src,$protocol,$sport,$dport,$dport,$icmp_type,$icmp_code,$flags,$length,$ttl,$dscp,$frag,$action,$description) = split(/;/, $line);

                if ($action eq "" || $action eq "null")
                {
                    $action = "discard";    # default action if none given
                }

                if ($description eq "")
                {
                    $description = "optimized rule";    # clould be ''
                }
                # use this when calculating top10
                # $ipnum = ip2num("10.1.1.1")
                
                # Type 1    IPv4 destination address
                # TODO: check for $dst is within our addresses should be made here, not later
                if ($dst_prev eq "")    # first line
                {
                    $dst_prev   = $dst;
                }
                else
                {
                    if ($dst ne $dst_prev)
                    {
                        $dst_uniq = 0;
                    }
                    $dst_prev = $dst;
                }

                # Type 2    IPv4 source address
                $src = "null" if ($src eq "");
                if ($src_prev eq "")    # first line
                {
                    $src_prev = $src;
                    $length_min = 64;       # ethernet minimum packet length
                    $length_max = 64;       # 
                }
                else
                {
                    if ($src ne $src_prev)
                    {
                        $src_uniq = 0;
                    }
                    $src_prev = $src;
                }
                
                # Type 3    IPv4 protocol
                # Identical in all lines

                # Type 4    IPv4 source or destination port
                # Type 5    IPv4 destination port
                # Type 6    IPv4 source port
                if ($sport =~ m/$isdigit/ && $sport_max =~ m/$isdigit/ && $sport_min =~ m/$isdigit/)
                {
                    $sport_max  = max($sport_max,   $sport);
                    $sport_min  = min($sport_min,   $sport);
                    $src_topports{ $sport } += 1;
                }
                else
                {
                    $sport_max = $sport_min = "null";
                }

                if ($dport =~ m/$isdigit/ && $dport_max =~ m/$isdigit/ && $dport_min =~ m/$isdigit/)
                {
                    $dport_max  = max($dport_max,   $dport);
                    $dport_min  = min($dport_min,   $dport);
                }
                else
                {
                    $dport_max = $dport_min = "null";
                }

                # TODO: handle ICMP type and code (type 7 and 8) -- which is not reported by fastnetmon
                # Type 7    IPv4 ICMP type
                # Type 8    IPv4 ICMP code

                # Type 9    IPv4 TCP flags (2 bytes incl. reserveret bits)
                if ($flags ne '' && $flags ne 'null')
                {
                    foreach (split(/,/, $flags))
                    {
                        $tcp_flags{$_} += 1;
                    }
                }

                # Type 10   IPv4 package length
                if ($length =~ m/$isdigit/ && $length_min =~ /$isdigit/ && $length_max =~ m/$isdigit/)
                {
                    $length_min = min($length_min,  $length);
                    $length_max = max($length_max,  $length);
                }
                else
                {
                    $length_max = $length_min = "null";
                }

                # Type 11   IPv4 DSCP
                # TODO: find the reporting format for DSCP (type 11)


                # Type 12   IPv4 fragment bits
                if ($frag ne '' && $frag ne 'null')
                {
                    $fragment_type = $frag;
                }
            }

            # prepare bgp flowspec rules
            if ($src_uniq == 0)
            {
                $src = "null";
            }

            if ($sport =~ m/null/)
            {
                $sport = "";
            }
            else
            {
                if ($sport_max =~ m/$isdigit/ && $sport_min =~ m/$isdigit/)
                {
                    if ($sport_min == $sport_max)
                    {
                        $sport = $sport_max;
                    }
                    else
                    {
                        $sport = ">=" . $sport_min . " <=" . $sport_max ;
                    }
                }
                else
                {
                    $sport = "";
                }
            }

            
            if ($dport =~ m/null/)
            {
                $dport = "";
            }
            else
            {
                if ($sport_max =~ m/$isdigit/ && $sport_min =~ m/$isdigit/)
                {
                    if ($dport_min == $dport_max)
                    {
                        $dport = "=" . $dport_max ;
                    }
                    else
                    {
                        $dport = ">=" . $dport_min . " <=" . $dport_max ;
                    }
                }
                else
                {
                    $dport = "";
                }
            }
            
            if ($length_min =~ m/null/)
            {
                $length = "";
            }
            else
            {
                if ($length_max =~ m/$isdigit/ && $length_min =~ m/$isdigit/)
                {
                    if ($length_min eq $length_max)
                    {
                        $length = "=" . $length_max;
                    }
                    else
                    {
                        $length = ">=" . $length_min . " <=" . $length_max ;

                    }
                }
                else
                {
                        $length = "";
                }
            }

            if ($fragment_type =~ /$isdigit/)
            {
                if ($fragment_type != 0)
                {
                    $frag = "is-fragment";
                }
            }
            else
            {
                $frag = "";
            }

            my $tcp_match_flags = "";
            foreach my $key (keys %tcp_flags)
            {
                if($tcp_flags{$key} > 0)
                {
                    $tcp_match_flags .= $key . " ";
                }
            }
            $tcp_match_flags =~ s/^\s+|\s+$//g;
            if ($tcp_match_flags eq '')
            {
                $tcp_match_flags = "null";
            }

#           logit("$rules_in_file rules reduced to: ");
#           logit("insert into database ...");
#           logit("match destination '$dst'");
#           logit("match source      '$src'");
#           logit("match protocol    '$protocol'");
#           logit("match sport       '$sport'");
#           logit("match dport       '$dport'");
#           logit("match fragment    '$frag'");
#           logit("match tcp flags   '$tcp_match_flags'");
#           logit("match length:     '$length'");
#           logit("then              '$action'");

#            logit("check if $uuid_administratorid really have rights to make rules on $dst");
#            $sql_query = "$check_admin_rights_on_dst";
#
#            for ($sql_query) {
#                s/__uuid_administratorid/$uuid_administratorid/g;
#                s/__dst/$dst/g;
#                s/'false'/false/g;
#                s/'null'/null/g;
#                s/''/'null'/g;
#            }
#            logit("running sql_query: $sql_query");
#            my $sth = $dbh->prepare($sql_query) or logit("Failed in statement prepare: $dbh->errstr");
#            $sth->execute()                     or logit("Failed to execute statement: $dbh->errstr");
#
#            my @tmparr;
#            while (my @row = $sth->fetchrow_array)
#            {
#                if ($row[0] eq 1)
#                {
#                    logit("ok: admin $uuid_administratorid may create rules for $dst");
                    #last loop;
                    logit("insert into ... $uuid/$fastnetmoninstanceid|$uuid_administratorid dest:$dst proto:$protocol port:$dport length:$length frag:$frag action:$action description: $description");
                    
                    # quote everything except null and false
                    $sql_query = $addrule;

                    for ($sql_query) {
                        s/__customerid/$customerid/g;
                        s/__uuid_administratorid/$uuid_administratorid/g;
                        s/__uuid/$uuid/g;
                        s/__blocktime/$blocktime/g;
                        s/__fastnetmoninstanceid/$fastnetmoninstanceid/g;
                        s/__dst/$dst/g;
                        s/__src/$src/g;
                        s/__protocol/$protocol/g;
                        s/__dport/$dport/g;
                        s/__sport/$sport/g;
                        s/__icmp_type/$icmp_type/g;
                        s/__icmp_code/$icmp_code/g;
                        s/__flags/$flags/g;
                        s/__length/$length/g;
                        s/__dscp/$dscp/g;
                        s/__frag/$frag/g;
                        s/__action/$action/g;
                        s/__description/$description/g;
                        s/'false'/false/g;
                        s/'null'/null/g;
                        s/''/'null'/g;
                    }
                    # Last line of defence to prevent wron announcements: Do not
                    # announce / withdraw networks outside our constituency
                    # if ($dst !~ m|(^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$| )
                    if ($dst =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)    # host with no space
                    {
                        $dst = $dst . "/32";
                    }
                    
                    # dst may be a list -- but this is currently not accepted in the database as the field type of src and dst is inet (meaning one cidr)
                    my $destinationprefix_is_within_my_network = 1;
                    foreach my $d (split(/ /, $dst))
                    {
                        my $dst_subnet = new NetAddr::IP $d;

                        logit ("testing $d = $dst_subnet within my networks: $destinationprefix_is_within_my_network");
                        foreach my $mynetwork (split ' ', $allmynetworks)
                        {
                            my $subnet = new NetAddr::IP $mynetwork;
                            if ($dst_subnet->within($subnet))
                            {
                                    logit("dst $dst_subnet is within $subnet");
                                    $destinationprefix_is_within_my_network = 0;
                            }
                        }
                        logit ("test done destinationprefix_is_within_my_network: $destinationprefix_is_within_my_network (0 is good)");
                    }
                        
                    if ($destinationprefix_is_within_my_network == 1)
                    {
                        logit("rule NOT added to database: dst is outside our constituency destinationprefix=$dst sourceprefix=$src ipprotocol=$protocol validfrom=$validfrom validto=$validto");
                    }
                    else
                    {
                        logit("running sql_query: $sql_query");
                        my $sth = $dbh->prepare($sql_query) or logit("Failed in statement prepare: $dbh->errstr");
                        $sth->execute()                     or logit("Failed to execute statement: $dbh->errstr");
                        # manglede der ern sth->finish her?
                        $sth->finish();
                    }
                    my @tmparr;
                    unlink $file or logit("Could not unlink $file $!");
#                }
#                elsif ($row[0] eq 0)
#                {
#                    logit("ERROR: admin $uuid_administratorid may NOT create rules for $dst");
#                    # TODO: move somewhere else for further investigation
#                    # unlink $file or logit("Could not unlink $file $!");
#                    last loop;
#                }
#            }
        }
        else
        {
            logit("no optimize as optimize = $optimize");

            if ($head !~ /head/)                        { logit("$file NOT ok: missing head");                      next;}
            if ($tail !~ /$file_finished_ok_string/)    { logit("$file NOT ok: missing $file_finished_ok_string");  next;}
            if ($#lines < 2)                            { logit("$file NOT ok: lines $#lines < 2");                 next;}

            my $rules_in_file = $#lines - 1; # base 0, subtract header/footer
            logit("$file ok type=$type optimize=$optimize ver=$version attack_info=$attack_info lines=$#lines");
            
            foreach my $line (@lines)
            {
                next if ($line =~ m/^head/);
                next if ($line =~ m/$file_finished_ok_string/);
                chomp($line);
                ($customerid,$uuid,$fastnetmoninstanceid,$uuid_administratorid,$blocktime,$dst,$src,$protocol,$sport,$dport,$dport,$icmp_type,$icmp_code,$flags,$length,$ttl,$dscp,$frag,$action,$description) = split(/;/, $line);
    
                # shouldn't be but better check
                if ($action eq "" || $action eq "null")
                {
                    $action = "discard";    # default action if none given
                }

                if ($description eq "")
                {
                    $description = "rule without description";
                }

                if ($dst =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)    # host with no space
                {
                    $dst = $dst . "/32";
                }
                
                # dst may be a list -- but this is currently not accepted in the database as the field type of src and dst is inet (meaning one cidr)
                my $destinationprefix_is_within_my_network = 1;
                my $dst_subnet = new NetAddr::IP $dst;
                logit ("testing $dst = $dst_subnet within my networks: $destinationprefix_is_within_my_network");

                foreach my $mynetwork (split ' ', $allmynetworks)
                {
                    my $subnet = new NetAddr::IP $mynetwork;
                    if ($dst_subnet->within($subnet))
                    {
                            logit("dst $dst_subnet is within $subnet");
                            $destinationprefix_is_within_my_network = 0;
                    }
                }
                logit ("test done destinationprefix_is_within_my_network: $destinationprefix_is_within_my_network (0 is good)");
                
                if ($destinationprefix_is_within_my_network == 1)
                {
                    logit("rule NOT added to database: dst is outside our constituency destinationprefix=$dst sourceprefix=$src ipprotocol=$protocol validfrom=$validfrom validto=$validto");
                }
                else
                {
                    logit("insert into ... $uuid/$fastnetmoninstanceid|$uuid_administratorid dest:$dst proto:$protocol port:$dport length:$length frag:$frag action:$action description:$description");
                    # quote everything except null and false
                    $sql_query = $addrule;

                    for ($sql_query) {
                        s/__customerid/$customerid/g;
                        s/__uuid_administratorid/$uuid_administratorid/g;
                        s/__uuid/$uuid/g;
                        s/__blocktime/$blocktime/g;
                        s/__fastnetmoninstanceid/$fastnetmoninstanceid/g;
                        s/__dst/$dst/g;
                        s/__src/$src/g;
                        s/__protocol/$protocol/g;
                        s/__dport/$dport/g;
                        s/__sport/$sport/g;
                        s/__icmp_type/$icmp_type/g;
                        s/__icmp_code/$icmp_code/g;
                        s/__flags/$flags/g;
                        s/__length/$length/g;
                        s/__dscp/$dscp/g;
                        s/__frag/$frag/g;
                        s/__action/$action/g;
                        s/__desciption/$description/g;
                        s/'false'/false/g;
                        s/'null'/null/g;
                        s/''/'null'/g;
                    }
                    logit("$sql_query");
                    my $sth = $dbh->prepare($sql_query) or logit("Failed in statement prepare: $dbh->errstr");
                    $sth->execute()                     or logit("Failed to execute statement: $dbh->errstr");
                }
            }
            unlink $file or logit("Could not unlink $file $!");
        } # noop

    }
    # exit on debug
    #logit("Exit in file", __FILE__, ", line:", __LINE__, ". Done"); exit 0;
}

sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }

sub getlocalipv4addr() {
# This idea was stolen from Net::Address::IP::Local::connected_to()
    my $socket = IO::Socket::INET->new(
        Proto       => 'udp',
        PeerAddr    => '8.8.8.8',
        PeerPort    => '53',
    );

    # A side-effect of making a socket connection is that our IP address
    # is available from the 'sockhost' method
    my $local_ip_address = $socket->sockhost;

    return ( $local_ip_address );
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
#   print "It's in the subnet\n";
#}
#else
#{
#   print "It's NOT in the subnet\n";
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

__DATA__

