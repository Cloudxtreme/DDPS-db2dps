
# i2dps daemon

`db2dps` is a small daemon running on the database server which converts
rules to BGP announcements. The daemon is controlled by `systemd`.  The
installation is done with `make`.

### Installation

Change directory to `../src/ddps-src/` and edit `Makefile` to match 
login and hostname / ip address of the ddps server host.

The default values from the ISO image is set in
`/opt/mkiso/specific/ddps/host.config` and
`/mkiso/specific/ddps/install.d/1_add-interface-cfg.sh`.

	TARGETHOST      = loginuser@192.168.99.10

Check ssh and sudo is working on the ddps host, then execute

	./remote.sh -v make install

Which will copy files to the target host, fetch and install
dependencies and install but not configure the database.

  - add version information to `db2dps`
  - install db2dps as a [systemd](https://en.wikipedia.org/wiki/Systemd) service which
    will start as part of the boot process

Usage and pseudo code below:

<!-- make md begin cd ../src/; make md -->
#### Name db2dps

 Database / rule manipulation for DDPS

#### Synopsis
 
  `db2dps [-V] [-v] [-d] [-s seconds]`
 
### Description

 `db2dps` process new _rulefiles_, and maintain rules in the database wile
 sending BGP flowspec updates to a number of BGP hosts. `db2dps` runs as
 a daemon controlled by systemd.

### Options

   - **-V**: print version information and exit
   - **-v**: verbose and run in foreground
   - **-d**: demonise
   - **-s** _seconds_: sleep time between database scan. Default is 20 seconds

#### Pseudo code
 
	read configuration || fail
	check args: print version and exit | demonise | run in foreground
	 
	connect to database || exit fail
	 
	query(all my networks)
	 
	while true; do
	{
	  if [ exit required ]
	  {
		break loop
		close database connection
		exit normal
	  }
	  else
	  {
		sleep except seconds on first loop
	  }
	 
	   if [ exist (new files with rules from fastnetmon) ]
		 if (query(insert rules in database) == OK)
			delete(rulefile) or warn

	  foreach bgphost do
	  {
		mkrulebase("announce", bgphost)
		{
		   if (bgphost requires all rules)
			  query(all rules)
		   else
			  query(NOT isactivated and NOT expired records)
		   continue if (query empty)
		   {
			 if (destination is within all my networks)
			 {
			   build rules suitable for bgphost
			   send rulebase to bgp host || warn
			   /* notice: this may block */
			 }
			 else
			 {
			   warn about attempt to filter for external network
			 }
		  }
		}
	  }
	  query(set isactivated for all announced rules in database)

	  foreach bgphost do
	  {
		mkrulebase("withdraw", bgphost)
		{
		   query(all isactivated rules)
		   select rules which are expired AND does not match a non-expired rule
		   foreach (bgphosts)
		   {
			 if (destination is within all my networks)
			 {
			   build rules suitable for bgphost
			   send rulebase to bgp host || warn
			   /* notice: this may block */
			 }
			 else
			 {
			   warn about attempt to filter for external network
			 }
		  }
		}
	  }
	  query(set isexpired for withdrawn rules in database)
	}

	close database connection and exit normal

### Author

 Niels Thomas Haugård, niels.thomas.haugaard@i2.dk

### Bugs

 Probably. Please report them to the author or the DDPS group. Please
 notice that this is early work.

<!-- make md end   -->

### Rulefiles

Rule files have the following format, with a _header_ describing the _rule type_
where only `fnm` for fastnetmon is in use, rule format if we should ever change it
and the _attack type_ for later optimisation. The last line is literally _last-line_
to avoid processing incomplete files:

	ruleheader
	rule
	rule
	last-line

The format is

	Rule header: type;vesion;attack_info
	type:        | fnm ...
	optimization | doop | noop | opop
	version:     | 1 ...
	attack_info: | icmp_flood | syn_flood | udp_flood | unknown | ...

	Rules customerid,uuid,fastnetmoninstanceid,administratorid,blocktime,1 .. 12,action,description

	customernetworkid:      Customer id (int)
	uuid:                   Mac address -- identify fastnetmon instance
	fastnetmoninstanceid:   Customers fastnetmon # (int)
	administratorid:        Administrator id (int)
	blocktime:              Minutes
	Type 1 - Destination Prefix: Only one CIDR is allowed due to database type limitations
	Type 2 - Source Prefix:      Only one CIDR is allowed due to database type limitations
	Type 3 - IP Protocol
	Type 4 – Source or Destination Port
	Type 5 – Destination Port
	Type 6 - Source Port
	Type 7 – ICMP Type
	Type 8 – ICMP Code
	Type 9 - TCP flags
	Type 10 - Packet length
	Type 11 – DSCP
	Type 12 - Fragment Encoding
	action:                Action upon match: accept discard or rate-limit 9600  (accept is a secret)

	last-line

| Option       | Description                                                                                 |
| ------------ | ------------------------------------------------------------------------------------------- |
| type         | rule file type, e.g. `fnm`                                                                  |
| optimization | **doop**: do optimization<br> **noop**: do not optimize<br> **opop**: optional optimization |
| version      | rule file version                                                                           |
| attack\_info | attack information from fastnetmon, e.g. `icmp_flood`, `syn_flood` and `udp_flood`          |

Example:

	head;fnm;doop;1;udp_flood
	1;00:25:90:47:2b:48;1;42;10;130.226.136.242;216.199.145.111;udp;60690;0;0;null;null;null;60;63;null;null
	1;00:25:90:47:2b:48;1;42;10;130.226.136.242;43.51.166.76;udp;60693;0;0;null;null;null;60;63;null;null
	1;00:25:90:47:2b:48;1;42;10;130.226.136.242;60.214.227.111;udp;60692;0;0;null;null;null;60;63;null;null
	last-line

	head;fnm;doop;1;syn_flood
	0;00:25:90:47:2b:48;1;42;10;130.226.136.242;66.141.26.81;tcp;14372;80;80;null;null;syn;60;63;null;0
	0;00:25:90:47:2b:48;1;42;10;130.226.136.242;161.185.77.224;tcp;14374;80;80;null;null;syn;60;63;null;0
	last-line

*Note*: the example is old and the two last fields is missing.

Some fields are read by `fnm2db` from its configuration file. The configuration file is written based
on information from the database:


| Var                       | Size  | Description             |
| ------------------------- | ----- | ----------------------- |
|**customernetworkid**		| `int` | describing the customer |
|**fastnetmoninstanceid**	| `int` | describing the customers fastnetmon which triggered the rule |
|**administratorid**		| `int` | describing the (pseudo) administrator which created the rule. The administrator cannot log in, but the database requires all rule to be made by someone. |

The design opens up for other kind of rule creators, e.g. [Cisco Netflow](https://en.wikipedia.org/wiki/NetFlow)
which is evaluated by CERT.

### Rule creation

Just my random thoughts, but having to implement something I wonder what is the
_best practice for creating rules to mitigate volumetric attacks based on flowspec_?

According to
[awsstatic.com](https://d0.awsstatic.com/whitepapers/DDoS_White_Paper_June2015.pdf)
DDoS attacks are most common at layers 3, 4, 6, and 7 of the Open Systems
Interconnection (OSI) model.

Layer 3 and 4 attacks correspond to the Network and Transport layers of the OSI
model: these are volumetric infrastructure layer attacks.

Layer 6 and 7 attacks correspond to the Presentation and Application layers of
the OSI model, these are as application layer attacks and only the volumetric
attacks can be detected by fastnetmon.


| #   |  Layer          |  Unit     |  Description                              |  Vector Examples               |
| --- | --------------- | --------- | ----------------------------------------- | ------------------------------ |
|  7  |  Application    |  Data     |  Network process to application           |  HTTP floods, DNS query floods |
|  6  |  Presentation   |  Data     |  Data representation and encryption       |  SSL abuse                     |
|  5  |  Session        |  Data     |  Interhost communication                  |  N/A                           |
|  4  |  Transport      |  Segments |  End-to-end connections and reliability   |  SYN floods                    |
|  3  |  Network        |  Packets  |  Path determination and logical addressing|  UDP reflection attacks        |
|  2  |  Data Link      |  Frames   |  Physical addressing                      |  N/A                           |
|  1  |  Physical       |  Bits     |  Media, signal, and binary transmission   |  N/A                           |

*From [awsstatic.com](https://d0.awsstatic.com/whitepapers/DDoS_White_Paper_June2015.pdf)*

Fastnetmon detects the following type of attacks:

  1. *syn_flood*: TCP packets with enabled SYN flag
  1. *udp_flood*: flood with UDP packets (so recently in result of amplification)
  1. *icmp flood*: flood with ICMP packets
  1. *ip_fragmentation_flood*: IP packets with MF flag set or with non zero fragment offset
  1. *DNS amplification*:
  1. *NTP amplification*:
  1. *SSDP amplification*:
  1. *SNMP amplification*:

First: it is sometimes possible to distinguish between legitimate and illegitimate packets, as
[Not All SYNs Are Created Equal](https://danielmiessler.com/study/synpackets/).
And empty UDP and TCP packet might be rare:

For Ethernet the _minimum payload_ is 42 octets when an 802.1Q tag is present and
46 octets when absent according to [wikipedia on ethernet
frames](https://en.wikipedia.org/wiki/Ethernet_frame). The minimum Layer 2
Ethernet frame size is 64 bytes for an _empty tcp or udp packet_.

![](https://nmap.org/book/images/hdr/MJB-TCP-Header-800x564.png)

We have the following values for creating a filter:

	Type 1 - Destination Prefix
	Type 2 - Source Prefix
	Type 3 - IP Protocol
	Type 4 – Source or Destination Port
	Type 5 – Destination Port
	Type 6 - Source Port
	Type 7 – ICMP Type
	Type 8 – ICMP Code
	Type 9 - TCP flags
	Type 10 - Packet length
	Type 11 – DSCP
	Type 12 - Fragment Encoding

Suggestion for rule creation:

| Attack type            | Mitigation     | Match on    |
| :--------------------- | :------------- | :---------- |
| syn_flood              | rate-limit     | tcp option (syn) protocol, destination port, tcp flags, size, (ttl would be nice but [is still in draft](https://tools.ietf.org/id/draft-ietf-idr-bgp-flowspec-label-00.txt)), size, and source any  |
| udp_flood              | rate-limit     | protocol and destination, size, host and port  |
| icmp flood             | discard        | protocol and destination  |
| ip_fragmentation_flood | rate-limit     | protocol size, and destination  |
| DNS amplification      | rate-limit     | protocol, size, port and destination |
| NTP amplification      | rate-limit     | protocol, size, port and destination |
| SSDP amplification     | discard        | protocol, size, port 1900, source any |
| SNMP amplification     | discard        | protocol, size, port, destination     |

Note: SSDP - _Simple Service Discovery Protocol_ (see [draft-cai-ssdp-v1-03](http://quimby.gnus.org/internet-drafts/draft-cai-ssdp-v1-03.txt) does not belong on a WAN anyway? It is used
for UPnP discovery. The same goes for TCP / UDP port 1 - 19.

SNMP does to my best understanding not pass the boundaries of a company
network, even not protocol version 3. And sacrificing monitoring data for
the sake of the network is fine with me.

Sometimes FastNetMon does not provide enough data, then don't match on the
missing information (e.g. icmp code and type). With e.g. ICMP flooding use
the fact that ICMP is not a critical protocol like e.g. HTTP or TCP SYN.

The objective is to reduce the rule files to a bare minimum of rules the
following is done for _type 10 - Packet length_ and _type 4 port_ assuming it
is the source port (and type 5 the destination port should fastnetmon detect a
change). So for both port and length the algorithm is sort-of:

	if (the value is string "null")
	then
		dont filter on value and use "null"
	else
		calculate min and max for value
		calculate the top 10 values
		if (min == max for value)
		then
			filter explicit on value, they are all identical
		else
			if (the top 10 values covers more than 10 %)
			then
				filter explicit on the top 10 values
			else
				dont filter on value and use "null"
			fi
		fi
	fi

	
## Other versions
A version of `i2dps` written in C is also available, but
_currently with unresolved memory / heap errors_. It also lacks code for
_white listing_ and _solving the problem with overlapping rules_.

The C development environment including memory leak test with
[valgrind](http://valgrind.org) may be installed this way:

    sudo apt-get -y update
    sudo apt-get -y upgrade
    sudo apt-get -y install build-essential
	sudo apt-get -y install man
    sudo apt-get -y install valgrind

Installation of the C version is documented in the `Makefile`.

