#!/usr/bin/perl -w
#
# $Header$
#


sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }


my $a = 1;
my $b = 2;

my $min ;
my $max ;

$max = max(1,2);
$min = min(1,2);

print "max = $max\nmin = $min\n";

