
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
need to change the lines to whatever your harts desire:

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
 
 ```bash
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
 ```

### Author

 Niels Thomas Haugård, niels.thomas.haugaard@i2.dk

### Bugs

 Probably. Please report them to the the author or the DDPS group. Please
 notice this is early work.


<!-- make md end   -->

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

