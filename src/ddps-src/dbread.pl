#!/usr/bin/perl -w
#

#
# Requirements
#
use strict;
use warnings;
use sigtrap qw(die normal-signals);
use DBI;				# database

use Getopt::Long qw(:config no_ignore_case);
use Net::SSH2;			# ssh v2 access to postgres db
use List::MoreUtils qw(uniq);
use Socket qw( inet_aton );
use NetAddr::IP;
use Path::Tiny;

#
# prototypes
#
sub main(@);
sub parseini();

my $driver	= "Pg"; 

my $inicfg	= "/opt/db2dps/etc/db.ini";

my @implemented_flowspecruleid;

# All BGP rule values
my ($flowspecruleid, $direction, $destinationprefix, $sourceprefix,
		$ipprotocol, $srcordestport, $destinationport, $sourceport, $icmptype,
		$icmpcode, $tcpflags, $packetlength, $dscp, $fragmentencoding
	);

my $db							= "";
my $dbuser						= "";
my $dbpass						= "";

my $allmynetworks				= "";
my $action						= "";
my $validfrom					= "";
my $validto						= "";
my $description					= "";

my $rules_total					= 0;

my $dbh;

################################################################################
# MAIN
################################################################################

main();

exit(0);

#
# Subs
#
sub parseini()
{
	my $section;
	my %data;

	open my $fh, '<', $inicfg or die "Could not open '$inicfg' $!";

	while (my $line = <$fh>)
	{
		if ($line =~ /^\s*#/)
		{
			next;		# skip comments
		}
		if ($line =~ /^\s*$/)
		{
			next;		# skip empty lines
		}

		if ($line =~ /^\[(.*)\]\s*$/)
		{
			$section = $1;
			next;
		}

		if ($line =~ /^([^=]+?)\s*=\s*(.*?)\s*$/)
		{
			my ($field, $value) = ($1, $2);
			if (not defined $section)
			{
				print "Error in '$inicfg': Line outside of seciton '$line'\n";
				next;
			}
			$data{$section}{$field} = $value;
		}
	}

	$db								= $data{'general'}{'dbname'};
	$dbuser							= $data{'general'}{'dbuser'};
	$dbpass							= $data{'general'}{'dbpassword'};

	close ($fh);
}

sub printrules()
{
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
}

sub main(@)
{
	parseini();
	printrules();
}


__DATA__

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
