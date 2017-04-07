#! /usr/bin/perl -w
#
# Testing the exabgp syntax
#	./test-bgp-rules.pl | ssh rnd@exabgp1 'cat > /var/run/exabgp/exabgp.cmd'
# and on root@exabgp1:
#	tail -f /var/log/syslog|sed 's/.*INFO//'
#

my $rule				= "";

my @types = ( "announce", "withdraw" );

foreach my $type (@types)
{

	my $src_spoofed			= 0;

	my $srcordestport		= "";

	my $flowspecruleid		= "1010101";

	my $sourceprefix		= "";
	my $sourceport			= "";
	my $destinationprefix	= "";
	my $destinationport		= "";
	my $ipprotocol			= "";

	my $icmptype			= "";
	my $icmpcode			= "";

	my $tcpflags			= "";

	my $packetlength		= "";

	my $dscp				= "";

	my $fragmentencoding	= "";

	my $action				= "";

	$sourceprefix		= "10.0.0.0/24";
	$destinationprefix	= "10.0.0.1/24";
	$destinationport	= "22,80,443";
	$ipprotocol			= "tcp";
	#$ipprotocol			= "udp";
	#$ipprotocol			= "icmp";
	#$ipprotocol			= "47";

	# tcp‐flags [ fin | syn | rst | push | ack | urgent ];
	$tcpflags			= "syn";

	#fragment [ not‐a‐fragment | dont‐fragment | is‐fragment | first‐fragment | last‐fragment ];
	$fragmentencoding	= "";

	# packet‐length <packet‐length‐expression>;
	$packetlength		= "117";

	$action				= "rate-limit 9600";
	$action				= "discard";

	#$src_spoofed		= 1;

	print "ipprotocol = '$ipprotocol'\n";

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

	if ($src_spoofed)										# source is spoofed
	{
		$sourceprefix = "";
	}

	# final rule
	$rule = "$type flow route $flowspecruleid { match { $sourceprefix $destinationprefix $destinationport $ipprotocol $tcpflags $packetlength } then { $action } } }";
	print "$rule\n";
#	sleep(5);
}
