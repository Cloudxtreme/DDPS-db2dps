
# i2dps daemon

``db2dps`` is a small daemon running on the database server which convert
rules to BGP announcements. The daemon is controlled by `systemd`.  The
installation is done with ``make``.

The current version of ``i2dps`` is written in Perl. It requires the following
Perl modules to be installed:

    sudo apt-get -y	install libnet-openssh-compat-perl liblist-moreutils-perl \
                            libnet-openssh-compat-perl libnet-ssh2-perl       \
                            libproc-daemon-perl libnetaddr-ip-perl            \
                            libdbi-perl libdbd-pg-perl

### Installation

On the database host, execute

	mkdir -p /opt/db2dps && chown sysadm:sysadm /opt/db2dps

Edit ``Makefile`` and copy the source for ``db2dps`` to ``/opt/db2dps``. You only
need to change the lines to whatever your heart desire:

	TARGETHOST      = sysadm@ddps.deic.dk
	GID             = sysadm
	UID             = sysadm

Change ``TARGETHOST`` and set up ``ssh`` credentials first. Either (depending
on your local environment) do

	./remote.sh -v make dirs

or copy the source to ``/opt/db2dps/src`` and execute:

	cd /opt/db2dps/src && make dirs

If that goes well then execute

	./remote.sh -v make all

or

	cd /opt/db2dps/src && make all

For the C version, the target will

  - fetch, extract and compile required libraries from github
  - compile db2dps and place binaries etc. below ``/opt/db2dps``
  - install db2dps as a [systemd](https://en.wikipedia.org/wiki/Systemd) service which
    will start as part of the boot process

For the Perl version the target will

  - add version information to ``db2dps``
  - install db2dps as a [systemd](https://en.wikipedia.org/wiki/Systemd) service which
    will start as part of the boot process

Usage and pseudo code below:

<!-- make md begin cd ../src/; make md -->
#### Name db2dps

 Database / rule manipulation for DDPS

#### Synopsis
 
  ``db2dps [-V] [-v] [-d] [-s seconds]``
 
### Description

 ``db2dps`` process new _rulefiles_, and maintain rules in the database wile
 sending BGP flowspec updates to a number of BGP hosts. ``db2dps`` runs as
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

 Probably. Please report them to the the author or the DDPS group. Please
 notice this is early work.

<!-- make md end   -->

### Rulefiles

Rulefiles has the following format, with a _header_ describing the _rule type_
where only `fnm` for fastnetmon is in use, rule format if we should ever change it
and the _attack type_ for later optimisation. The last line is literally _last-line_
to avoid processing incomplete files:

	ruleheader
	rule
	rule
	last-line

The format is

	Rule header: type;vesion;attack_info;
	type: fnm | ...
	version: 1 | ...
	attack_info: icmp_flood | syn_flood | udp_flood | unknown | ...
	Rules: networkid,uuid,blocktime,date,time,1,2,3,4,5,6,7,8,9,10,11,12
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

Example:

	fnm;1;syn_flood;
	0;00:25:90:47:2b:48;10;130.226.136.242;66.141.26.81;tcp;14372;80;14372;0;0;syn;60;63;0;0
	0;00:25:90:47:2b:48;10;130.226.136.242;161.185.77.224;tcp;14374;80;14374;0;0;syn;60;63;0;0
	last-line

## Other versions
A version of ``i2dps`` written in C is also available, but
_currently with unresolved memory / heap errors_. It also lacks code for
_white listing_ and _solving the problem with overlapping rules_.

The C development environment including memory leak test with
[valgrind](http://valgrind.org) may be installed this way:

    sudo apt-get -y update
    sudo apt-get -y upgrade
    sudo apt-get -y install build-essential
    sudo apt-get -y install valgrind

Installation of the C version is documented in the ``Makefile``.

