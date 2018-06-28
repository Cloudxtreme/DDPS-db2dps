#! /usr/bin/env perl -w
#
#
use Test::Simple tests => 17;

my ${match_flowspec_port}   = '';
my ${ok_match_string}  = "";
my ${no_match_string}  = "";
my $tmpstr = "";

${match_flowspec_port}  = '\A(=\d+\-\d+)\s+?\Z|\A(=[<>]?\d+\s+)+\Z';

my @tmpfail = ("=100 =200 =<100 =>200 =100-200 ", "=100 =200 =<A00 =>200", "=80&443");

print "Testing bgp flowspec port specification regex m/${match_flowspec_port}/gi\n";
print "Testing range expression and not-range expression\n";

for my $fail_match_string (@tmpfail) {
    ok( ${fail_match_string}  !~ m/${match_flowspec_port}/gi, "no match on '${fail_match_string}'" );
}

# test port range: 0-65535 AND first<=last
my @tmparr = ("=100-200", "=0 =0 =<0 =>0", "=100 =200 =<100 =>200", "=80-8080");

for $ok_match_string (@tmparr) {
    $tmpstr = $ok_match_string;
    $tmpstr =~ tr/-<>=/ /d;

    if ($ok_match_string =~ m/-/) {
        print "Found range expression\n"; # must be in range and lowest first
        my ($first, $last) = (split ' ', $tmpstr);
        for my $tmp ($first, $last) {
            ok($tmp >= 0 && $tmp <= 65535, "port $tmp' within 0-65535");
        }
        ok($first le $last, "$first <= $last");
    }
    else 
    {
        print "Found non-range expression\n";
        for my $tmp (split ' ', $tmpstr) {
            ok($tmp ge 0 && $tmp le 65535, "port '$tmp' within 0-65535");
        }
    }
}

__DATA__

Regex may be used for both port and package length, if the upper and lower limit
for port is set to 0-65535 and for package 20-9000, see below.

## Port specification(s):

### Range:

The lowest port numer for filtering is 0, while the largest port number is an
unsigned short 2^16-1: 65535, as specified in RFC 793. Port 0 which is not a
valid port may be set in a UDP or TCP package and transported 'over the wire',
see [Port Authority Database, Port 0](https://www.grc.com/port_0.htm)

### Filter specification(s):

For each rule only one of the following syntaxes are allowed:

  - **range**: _lower boundary_ - _upper boundary_, e.g. `=80-8080`
  - **any combination of**: `=port =port >=port <=port ...` e.g. `=80 =443 <=1023`

The `&` sign is not accepted by Juniper: it breaks the BGP sesstion.

You may not specify both a range and something else.

## Package length specification(s):

Here the length of an IP datagram is messured, so the range is between 20 and
65535 (bytes).

### Range:

Size of Ethernet frame - 24 Bytes
Size of IPv4 Header (without any options) - 20 bytes
Size of TCP Header (without any options) - 20 Bytes
So total size of empty TCP datagram - 24 + 20 + 20 = 64 bytes

Size of UDP header - 8 bytes
So total size of empty UDP datagram - 24 + 20 + 8 = 52 bytes

But I think you can create an empty IP frame with 20 bytes

The maximum size of an IP datagram is 65535 bytes while jumbo frames
may be 9038 bytes long [see wikipedia](https://en.wikipedia.org/wiki/Jumbo_frame).

I don't think we should impose an upper limit.

### Filter specification(s):

  - **range**: _lower boundary_ - _upper boundary_, e.g. `=20-9000`
  - **any combination of**: `=length =length >=length <=length ...` e.g. `=348 =512 >=1470`

   Copyright 2017, DeiC, Niels Thomas Haugård

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.


