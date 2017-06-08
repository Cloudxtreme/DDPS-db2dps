#!/usr/bin/perl -w
#
# DONE	1.	Move all SQL statements to the Perl module `/opt/db2dps/lib/sqlstr.pm`
# DONE	2.	Define all SQL statements as `our ...` in db2dps.pl
#		3.	Split repetitive actions into functions
#		4.	New function `sub reannounce(@)`, @ is a list of customerid's with withdrawn
#			rules that also may have still valid rules which should be announced again
#		5.	Start unit test: rule files with
#			- errors
#			- different options
#			- uuid / name so they can be deleted from the database and not sent to exabgp
#			  but removed after the test

#
# Requirements
#
use 5.10.0;
use warnings;

my $customerid				= "1";			my $uuid		= "asdf-sdf-sadf-sadf";
my $administratorid			= "42";			my $blocktime	= "10";
my $fastnetmoninstanceid	= "2";			my $dst			= "10.0.0.1";
my $src						= "11.0.0.1";	my $protocol	= "tcp";
my $dport					= "80";			my $sport		= "null";
my $icmp_type				= "null";		my $icmp_code	= "null";
my $flags					= "ack";		my $length		= "1470";
my $dscp					= "null";		my $frag		= "null";
my $action					= "discard";
my $sql_query				= $addrule;

our $addrule;

require 'sqlstr.pm';

$sql_query	= $addrule;

for ($sql_query) {
	s/__customerid/$customerid/g;
	s/__uuid/$uuid/g;
	s/__administratorid/$administratorid/g;
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
}

say "new rules = ${sql_query}\n";

