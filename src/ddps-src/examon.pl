#!/usr/bin/perl -w
#
# $Header$
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
################################################################################
#INCLUDE_VERSION_PM
################################################################################

#
# Requirements
#
use English;
use FileHandle;
use Getopt::Long qw(:config no_ignore_case);
use Digest::MD5;
use sigtrap qw(die normal-signals);
use POSIX;
use Sys::Syslog;
use Net::SSH2;

#
# prototypes
sub parseini();
sub main(@);

#
# Global vars
#
my $usage   = " $0  --verbose|v\n";
my $inicfg  = "/opt/db2dps/etc/db.ini";
my %data;

#
# Subs
#

sub main(@)
{
    # purpose     :
    # arguments   :
    # return value:
    # see also    :

    #
    # Parse and process options
    #
    if (!GetOptions('verbose|v'       => \$verbose))
    {
        print "$usage";
        exit 0;
    }

    parseini();
    # print"db=$db, dbuser=$dbuser, dbpass=$dbpass, newrulesdir=$newrulesdir\n";

    $hostlist                       = $data{'general'}{'hostlist'};

    my %exabgp_uptimes = ();
    my @hostlist = split(' ', $hostlist);
    while(1)
    {
        foreach my $host (@hostlist) {
            my $sshuser         = $data{$host}{'sshuser'};          $sshuser =~ tr/\"//d;
            my $identity_file   = $data{$host}{'identity_file'};    $identity_file =~ tr/\"//d;
            my $public_key      = $data{$host}{'public_key'};       $public_key =~ tr/\"//d;
            my $filtertype      = $data{$host}{'filtertype'};       $filtertype =~ tr/\"//d;
            my $exabgp_pipe     = $data{$host}{'exabgp_pipe'};      $exabgp_pipe =~ tr/\"//d;


            logit("$host of $hostlist: $sshuser | $exabgp_pipe");

            my $ssh2 = Net::SSH2->new(timeout => 100);
            if (! $ssh2->connect($host)) {
                logit("Failed connection to $host");
            }
            if (! $ssh2->auth_publickey($sshuser,$public_key,$identity_file) ) {
                logit("public/private key authentication for $sshuser to $host failed with: $!");
                logit("Please check modes for .ssh/* for user\@host and ~/.ssh/authorized_keys too");
                logit("Some versions of Net::SSH2 may only support rsa");
            }

            # Get PID of process exabgp (ps) remove blanks (tr) and get start time in seconds (stat)
            #my $cmd = "stat -c%X /proc/`ps -C exabgp -o pid=|tr -d ' '`";
            # Use GNU date to calculate start time in seconds
            #my $cmd = 'echo $(export TZ=UTC0 LC_ALL=C; date -d "$(ps -o lstart= -C exabgp )" +%s)'

            # get start time of exabgp process as a text string, if it changes then do something
            # as new processes do not start earlier than old ones
            my $cmd = "ps -C exabgp -o lstart=";

            my $chan = $ssh2->channel();
            $chan->blocking(0);
            $chan->shell();

            my $len = 0;
            my $buf = 0;

            $chan->write("$cmd\n");
            select(undef,undef,undef,0.2);
            print $buf while defined ($len = $chan->read($buf,512));

            #my @CMDS = ( 'whoami', 'umame' );
            #foreach $cmd (@CMDS) {
            #      #chomp $cmd;
            #      my $command = $channel->exec("$cmd") or die $_;
            #      my $output;
            #      my $len = $channel->read($output,2048);
            #      print "cmd is '$cmd', output is '$output'\n";
            #  }


            #--------------------------------------------------------------------------------------#
            # TODO
            #     Run on ddps, loop all hosts (parse ini)
            #     loop:
            #       connect to exabgpx, check runtime for exabgp greater than last check, next
            #       on error:  touch  local file only if we have not pushed the big red button
            #       sleep
            #
            # ssh trust must be enabled anyway, program in perl for ease of ini parsing
            # check with shell code: 
            #   cat << 'EOF' | ssh -qT localhost
            #   ps -o etimes= -p `ps -C exabgp -o pid=` 2>/dev/null
            #   EOF
            #   stat -c%X /proc/`ps -C exabgp -o pid=|tr -d ' '`
            #
            # which will be empty if exabgp is not running or else print time since start in seconds
            #--------------------------------------------------------------------------------------#

        }
        sleep(2);
    }

    exit 0;
}

sub parseini()
{
    open my $fh, '<', $inicfg or mydie("Could not open '$inicfg' $!");

    while (my $line = <$fh>) {
        if ($line =~ /^\s*#/) {
            next;      # skip comments
        }
        if ($line =~ /^\s*$/) {
            next;      # skip empty lines
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
            }          
            $data{$section}{$field} = $value;
        }
    }

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

################################################################################
# MAIN
################################################################################

main();

exit 0;

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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#++
# NAME
#   template.pl 1
# SUMMARY
#   Short description
# PACKAGE
#   file archive exercicer
# SYNOPSIS
#   template.pl options
# DESCRIPTION
#   \fItemplate.pl\fR is used for ...
#   Bla bla.
#   More bla bla.
# OPTIONS
# .IP o
#   I'm a bullet.
# .IP o
#   So am I.
# COMMANDS
#   
# SEE ALSO
#   
# DIAGNOSTICS
#   Whatever.
# BUGS
#   Probably. Please report them to the call-desk or the author.
# VERSION
#      $Date$
# .br
#      $Revision$
# .br
#      $Source$
# .br
#      $State$
# HISTORY
#   $Log$
# AUTHOR(S)
#   Niels Thomas Haugård
# .br
#   E-mail: thomas@haugaard.net
# .br
#   UNI-C
# .br
#   DTU, Building 304
# .br
#   DK-2800 Kgs. Lyngby
# .br
#   Denmark
#--
