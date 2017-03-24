#!/usr/bin/perl -w
#
# !LATEST!
#
# each rule file has the format:
# 22 fields separated by semi-colon: ;
#  1 last line with the word last-line
#

my $customernetworkid	= "";
my $rule_name			= "";
my $administratorid		= "";
my $blocktime			= "";		# blocktime
my $fastnetmoninstanceid= "";
my $destinationprefix	= "";
my $sourceprefix		= "";
my $ipprotocol			= "";
my $srcordestport		= "";
my $estinationport		= "";
my $sourceport			= "";
my $icmptype			= "";
my $icmpcode			= "";
my $tcpflags			= "";
my $packetlength		= "";
my $dscp				= "";
my $fragmentencoding	= "";

my $dir = "/home/sftpgroup/newrules/upload";

opendir (DIR, $dir) or die $!;
while ( my $node = readdir(DIR) )
{
	next if ($node =~ /^\./);
	push (@rulefiles, $node);
}
closedir DIR;

foreach my $r (@rulefiles)
{
	my $file_not_ok = 0;
	my $file_finished_ok_string = "last-line";
	my $file_finished_ok = 0;
	#print "$r\n";
	my @flowspecvalues = ();
	my $file = $dir . "/" . $r;
	open my $input, '<', $file or die "can't open $file: $!";
	while (<$input>)
	{
	    chomp;
	    # read 12 flowspec fileds from file

		if (/\Q$file_finished_ok_string/)
		{
			$file_finished_ok = 1;
		}
		else
		{
			@flowspecvalues = split(';', $_);
		}
	}

	my $i = $#flowspecvalues + 1;
	if ($i ne 22)
	{
		#print "fail: fields in file $file is $i should be 22\n";
		$file_not_ok ++;
	}
	elsif ($i eq 0)
	{
		#print "no data in $file\n";
		$file_not_ok ++;
	}
	else
	{
		#print "ok:  fields in file $file is $i should be 22\n";
	}

	for (@flowspecvalues )
	{
		if (! $_ )
		{
			#print "fail in filed: $_\n";
			#print "@flowspecvalues\n";
			$file_not_ok ++;
		}
	}
	close $input or die "can't close $file: $!";

	if ($file_not_ok gt 0)
	{
		print "$file NOT ok\n";
	}
	else
	{
		print "$file ok\n";

		print "rules: @flowspecvalues\n";
	}
}

__DATA__



Skal læse følgende fra rulefile:

  1 customernetworkid
  2 rule_name
  3 administratorid
  4 validto (blocktime)
  5 fastnetmoninstanceid
  6 destinationprefix
  7 sourceprefix
  8 ipprotocol
  9 srcordestport
 10 destinationport
 11 sourceport
 12 icmptype
 13 icmpcode
 14 tcpflags
 15 packetlength
 16 dscp
 17 fragmentencoding


insert into flow.flowspecrules(
    flowspecruleid,
	customernetworkid,
	rule_name,
	administratorid,
	direction,
	validfrom,
	validto,,
    fastnetmoninstanceid,
	isactivated,
	isexpired,
	destinationprefix,
	sourceprefix,
	ipprotocol,
	srcordestport,
    destinationport,
	sourceport,
	icmptype,
	icmpcode,
	tcpflags,
	packetlength,
	dscp,
    fragmentencoding
)
values
(
    ( select coalesce(max(flowspecruleid),0)+1 from flow.flowspecrules),
    1
    $uuid,
    2,
    in,
    now(),
    now()+interval $blocktime minutes,
    1,
	false,
	false,
	$dst,
	$src,
	$protocol,
	$dport,
    $dport,
	$sport,
	null,
	null,
	null,
	$size,
	null,
    null
);



cat << EOF > test-rule
customernetworkid;rule_name;administratorid;blocktime;fastnetmoninstanceid;destinationprefix;sourceprefix;ipprotocol;srcordestport;destinationport;sourceport;icmptype;icmpcode;tcpflags;packetlength;dscp;fragmentencoding;
last-line
EOF
