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

	# exabgp 4.0 (experimental) uses json, example on https://github.com/pavel-odintsov/fastnetmon/wiki/BGP-Flow-Spec-as-JSON
	# we uses 3.x so this is a grusome hack -- and on exabgp 3 the syntax may change ...
	# seems to work, either:
	# port,port,port, port < something, port > something
	# or
	# port - range

	$destinationport	= "[ =22 =80 =443 ]";	# ok
	$destinationport	= "[ =0-19 ]";			# ok but do not mix
	$destinationport	= "[ <19 ]";			# ok
	$destinationport	= "[ <19 >1024 ]";		# ok
	$destinationport	= "[ <19 =22 >1024 ]";	# ok

	$ipprotocol			= "tcp";
	#$ipprotocol			= "udp";
	#$ipprotocol			= "icmp";
	#$ipprotocol			= "47";

	# tcp‐flags [ fin | syn | rst | push | ack | urgent ];
	$tcpflags			= "syn";

	#fragment [ not‐a‐fragment | dont‐fragment | is‐fragment | first‐fragment | last‐fragment ];
	$fragmentencoding	= "";

	# packet‐length <packet‐length‐expression>;
	$packetlength		= "=64 =117";

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


__DATA__

From https://github.com/Exa-Networks/exabgp/blob/master/qa/conf/api-flow.run

announce_flow_1 = 'announce flow route { match { source 10.0.0.2/32; destination 10.0.0.3/32; destination-port =3128; protocol tcp; } then { rate-limit 9600; } }'
withdraw_flow_1 = 'withdraw flow route { match { source 10.0.0.2/32; destination 10.0.0.3/32; destination-port =3128; protocol tcp; } }'
announce_flow_2 = 'announce flow route { match { source 10.0.0.1/32; destination 192.168.0.1/32; port [ =80 =8080 ]; destination-port [ >8080&<8088 =3128 ]; source-port >1024; protocol [ udp tcp ]; } then { rate-limit 9600;}}'


