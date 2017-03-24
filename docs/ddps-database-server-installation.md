
# DeIC DPS: database server installation 

This document describes the _installation process_ of _one host_, not the configuration
nor the design of the system.

Also, this document describes the installation for the DeiC DPS server: replace users
and ssh public key's with your own.

## The database host

This is the description of the installation procedure for version 1.0 of the database
host used in _DeIC Distributed Denial of Service Protection System_.        
The system is build on Ubuntu 16.01, postgres, node.js and a number of internal
developed applications. This procedure covers both the _production_ and _development_
environment.

  - **hostname**: ddps
  - **IPv4 address of developemet server**: 10.33.0.97 
  - **IPv4 address of test server**: 172.16.201.113)

### Document warning

This document contain valid commands: you may copy and paste to your hards desire or
grab all commands at once with (please mind the **tabs**):

	sed '/^	/!d; s/^	//' ddps-dev.md

Commands with long lines normally doesn't print well and folding such lines may
brake with functionality. An example is printing an [ssh rsa
key](http://security.stackexchange.com/questions/23383/ssh-key-type-rsa-dsa-ecdsa-are-there-easy-answers-for-which-to-choose-when)
as [here text](https://en.wikipedia.org/wiki/Here_document). This is not the
case in this text: all commands may be executed without editing first.

Notice the ``sudo`` is not shown for commands that require administrative
rights.

### Prerequisite

Select an IPv4 address and update DNS for the host ``bgpdb``, then install
Ubuntu server 16.01, use all disk space without LVM, set the static IPv4
address and install add the package sshd. Do **not** select automatic update.

Create a user - we use ``sysadm`` - and generate ssh keys for ``sysadm`` and
``root``:

     ssh-keygen -t rsa -b 4096

Add required keys to allow for unattended access (backup, administration etc.):
<!-- html fold -w 76 .... -->

	cd /root/.ssh
	cat << EOF | tr -d '\n' > authorized_keys
	ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFzg7XMQuCJ/nOs4eUN734PsPEbE82xYDS04qx
	gaC0CotkUK+4hzGUeHawuuIDAtJL6LTS304mYj7MYaFTG/Qx0QK5xopzVriX3WmZtnuDq5d7ddzO
	IcmpYDYG6lHnEZs/LZhOEultYlEKtzNozDFqUyfuzAFpgv1harC+2YPzxgw0CLZFWz10YOQDo9sp
	NEQX684Zy4j/0IMa+e8ijPFiGhGItZkRkHDUkf15G9K9F2rnHecIHo6IL0rMARrktexiQsVLCl0l
	FZVDP3ApiHaaDoQClP106XuSqd+oBUGN2/3Hkn8gtnDWUREeTCtS6QHfFa1NYtR5Z0MJUjGscNGT
	sBF8p4rHKG2sumf0HFi7mGQ5TmAGF1+/eIZTOB2Fq5YxWrwKdCqx/KbgkgGEc9Mgm3QtLEqyPr7v
	aT0hbtSip30Ad40RWOWlIu50ljz8bijxRWMyqwbVrcaOS+KVitbWwKubf1oeHEVeLbcFNMgj74HW
	m+wqqqRwbgaL7yU0WTnzClns/d4+zHMxK3XjKHjOJsmaeDPVDEHe66nGG1iF+zvVhaC5KHGHZwuH
	2dbjETvF5CxnNy58GRZc098gBy+bOf6NKBHXfJgU+X22NjBPrZCZ5LDU/J6DHF5ZCAT/akJ8wmtP
	Ian9WEQcBzRkTRq1O6w5BhJ0NB3ujaTR8TwsOw==
	EOF

Set mode for files and folder:

	chmod 600 *
	chmod 700 .

Add the following local developed packages from ``buh.ssi.i2.dk``:

     dpkg -i  cmod_1.1-2.deb              \
              dailybuandupdate_1.6-1.deb  \
              grouproot_1.2-1.deb

Patch the system with the command:

	/usr/local/bin/adhoc_update.sh -v

The system will reboot if required. The command (part of dailybuandupdate) runs
once a day at midnight.

Generate locale if required:

	locale-gen da_DK.UTF-8

### Developers
Add developers / system users, same password (``1qazxsw2``) - please change
asap and upload rsa ssh keys as password based access will be disabled.

	(
	cat << EOF | awk -F';' '
	{
		printf( "useradd -m -u %s --group staff -c \"%s\" -d /home/%s/	\
			-p \"`mkpasswd 1qazxsw2`\" -s /bin/bash %s\nusermod -a	\
			-G sudo %s\nsudo chage -d 0 %s\n\n", $3, $2,		\
			tolower($1), tolower($1), tolower($1), tolower($1) );
		}
	'
	nice;Nicolai Ernst;8282
	uninth;Niels Thomas Haugaard;8281
	adue;Anders Mundt Due;8227
	asmo;Ashokaditya Mohanty;1921
	tangui;Tangui Coulouarn;4217
	kasm;Kasper Sort;8233
	EOF
	) | /bin/sh

The following will allow all members of the group ``sudo`` root access without password:

	echo '%sudo	ALL=(ALL:ALL) NOPASSWD:ALL' > etc/sudoers.d/sudogrp
	chmod 0440 /etc/sudoers.d/sudogrp

Now all developers has [unrestricted administrator privileges using
sudo](https://en.wikipedia.org/wiki/Pottery_Barn_rule).

### Changes to Secure Shell

In ``/etc/ssh/sshd_config`` add ``AllowTcpForwarding yes``, disable
password based login and add a section for the group ``sftpgroup``:

	test -f /etc/ssh/sshd_config.org || {
		cp /etc/ssh/sshd_config.org /etc/ssh/sshd_config.org
	}
	(
	sed '
	   /^AllowTcpForwarding/d;
	  s/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/;
	  s/^#[ \t]*PasswordAuthentication[ \t]yes*/PasswordAuthentication no/;
	  s/^PasswordAuthentication.*/PasswordAuthentication no/;
	  s/^UsePAM.*/UsePAM no/;
	  s/\(X11Forwarding.*\)/AllowTcpForwarding yes\n\1/' < \
	      /etc/ssh/sshd_config.org
	cat << EOF
	Match Group sftpgroup
		# Force the connection to use SFTP and chroot to the required directory.
		ForceCommand internal-sftp
		ChrootDirectory %h
		# Disable tunneling, authentication agent, TCP and X11 forwarding.
		PermitTunnel no
		AllowAgentForwarding no
		AllowTcpForwarding no
		X11Forwarding no
	EOF
	) > /etc/ssh/sshd_config
	chmod 0644 /etc/ssh/sshd_config
	chown root:root /etc/ssh/sshd_config
	service ssh restart

We now have a fairly secure system with automatic update once a day.

### Application users

The database runs by default as the user _postgres_. The daemon ``db2dps`` runs
as the user _ddpsadm/ddpsadm_ while the web application runs as the user
_also not defined yet_.

The user ``ddpsadm`` does not require administrative rights.

    useradd -m -u 8888 --group staff -c "DDPS admin" -d /home/ddpsadm/   \
            -p "`mkpasswd 1qazxsw2`" -s /bin/bash ddpsadm

New rules will be uploaded with _sftp_ to the user ``newrules``. The ssh
configuration for the user (actually the group) is locked down to
the subsystem ``internal-sftp``.

Credentials etc. is set up this way:

	addgroup --system sftpgroup

	mkdir /home/sftpgroup
	useradd -m -c "DDPS rules upload" -d /home/sftpgroup/newrules/   \
			-s /sbin/nologin newrules

	usermod -G sftpgroup newrules

Changing owner of the home directory prevents changes by the upload user:

	chown root:root /home/sftpgroup /home/sftpgroup/newrules/
	chmod 755 /home/sftpgroup /home/sftpgroup/newrules/

Rules will be uploaded to the upload directory ``upload`` which
has mode 777 in order for the rules to be deleted:

	mkdir /home/sftpgroup/newrules/upload
	chown newrules:newrules /home/sftpgroup/newrules/upload
	chmod 777 /home/sftpgroup/newrules/upload

The users ssh configuration is locked down too, after keys etc. has been setup:

	mkdir /home/sftpgroup/.ssh
	cd 
	cat << EOF | tr -d '\n' > /home/sftpgroup/.ssh/authorized_keys
	ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHlbMohteTKrthwscc9r8tN19iFzB5aciX6D3X
	0XMjiZX13Zv/0Kak+Ty6g2One2OKKxwKlO7APirFRmgLgDKUVG7X7bt9gDJHz2fg5J2AIBr5iIc8
	8d3H+xyti4uOL0kc2RjCQKenJfKfEfA8YaFZZ/cCo9wY9Isia+6IveQSyMFg6Z870EwDEgIb5k5y
	9CNfrZSkD3tjnrg/3QejJf3fulwa5PASwK2LFxLx5h00JOikEOjs12YaOa4bpBFblLYyMW6BWtZA
	RrS0AYx3XJ06yBjBlo3/JkkBQfbftPzOyw/SLCB9kVXVEhoegw187cS//tADKpsUf7DeFLmzkFqZ
	 root@fastnetmon
	EOF
	chown -R newrules:newrules /home/sftpgroup/.ssh
	chattr +i /home/sftpgroup/.ssh /home/sftpgroup/.ssh/*

The ``chattr`` command _prevents all changes to .ssh and authorized_keys_
and can only be undone with ``chattr -i ... `` by an administrator.

Other systems may in the future upload rules the same way but as a different
user configured the same way.

### Database installation

Ubuntu 16.04 has PostgreSQL 9.5.5 in its default repository. PostgreSQL 9.6
requires the following:

	apt-get -y update
	echo "deb http://apt.postgresql.org/pub/repos/apt/ \
	 `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
	wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | \
		apt-key add -
	apt-get -y install postgresql postgresql-contrib libpq-dev

as the package libpq-dev is required for i2dps.

Check the installed server and client development versions are as expected:

	pg_config --version
	# expected output: PostgreSQL 9.6.1
	psql --version
	# expected output: psql (PostgreSQL) 9.6.1

### PostgreSQL, Database users, database and schema

Modify ``pg_hba.conf`` to allow access for the database administrator ``flowuser``:

In ``/etc/postgresql/9.6/main/pg_hba.conf`` add ``local all flowuser password``:

	test -f /etc/postgresql/9.6/main/pg_hba.conf.org || {
		cp	/etc/postgresql/9.6/main/pg_hba.conf		\
			/etc/postgresql/9.6/main/pg_hba.conf.org
	}
	awk '
	{
		if ($1 == "local" && $2 == "all" && $3 == "postgres")
		{
			print $0
			print "local all flowuser peer"
			print "local all dbadmin md5"
			next
		}
		{ print; next; }
	}'	/etc/postgresql/9.6/main/pg_hba.conf.org >		\
		/etc/postgresql/9.6/main/pg_hba.conf

	chmod 0640 /etc/postgresql/9.6/main/pg_hba.conf
	chown postgres:postgres /etc/postgresql/9.6/main/pg_hba.conf
	service postgresql restart

You may now connect directly to PostgreSQL using port forwarding from 127.0.0.1
with

	ssh -v -L 5432:127.0.0.1:5432 sysadm@172.16.201.113

#### Create database and add master data

Execute for following scripts as the user ``postgres``:

	echo 'psql -f db/1_create_netwlow_db.sql'             | su postgres
	echo 'psql -f db/2_create_netflow_schema.sql'         | su postgres
	echo 'psql netflow -f db/netflow_flow.icmp_codes.sql' | su postgres
	echo 'psql netflow -f db/netflow_flow.icmp_types.sql' | su postgres
	echo 'psql netflow -f db/netflow_flow.protocols.sql'  | su postgres
	echo 'psql netflow -f db/netflow_flow.services.sql'   | su postgres

  - ``1_create_netwlow_db.sql``: creates database and database administrators,
    script created by hand
  - ``2_create_netflow_schema.sql``: creates the database schema, script based
    on [a database schema dump](https://www.chrisnewland.com/postgres-dump-database-schema-with-or-without-data-61)
  - ``netflow_flow.*``: table content build with ``db/dumpit.sh`` (icmp codes
    and types, protocols and well known services).

<yellownote>TODO Add customers </yellownote>

### Apache / NGINX configuration

<yellownote>TODO:</yellownote>

### Node.js

<yellownote>TODO:</yellownote>

### i2dps - flowspec rules to exabgp instances

 ``db2dps`` is a small daemon running on the database server. It is started from
 ``/etc/init.d``. The installation is done with ``make``.

The current version of ``i2dps`` is written in Perl. It requires the following
Perl modules to be installed:

    sudo apt-get -y	install libnet-openssh-compat-perl liblist-moreutils-perl \
                            libnet-openssh-compat-perl libnet-ssh2-perl       \
                            libproc-daemon-perl libnetaddr-ip-perl            \
                            libdbi-perl libdbd-pg-perl

Usage and pseudo code below:

<!-- make md -->
#### Usage and pseudo code below for ``db2dps``
 
  ``db2dps [-V] [-v] [-d] [-s seconds]``
 
   - **-V**: print version information and exit
   - **-v**: verbose and run in foreground
   - **-d**: demonise
   - **-s** _seconds_: sleep time between database scan. Default is 20 seconds
 
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
<!-- make md -->

A version of ``i2dps`` written in C is also available, but
_currently with unresolved memory / heap errors_. It also lacks code for
_white listing_ and _solving the problem with overlapping rules_.

The C development environment including memory leak test with
[valgrind](http://valgrind.org) may be installed this way:

    sudo apt-get -y update
    sudo apt-get -y upgrade
    sudo apt-get -y install build-essential
    sudo apt-get -y install valgrind

Install the Perl version of ``i2dps`` this way - the C version is documented in the
``Makefile``:

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

### System wide backup and restore

Backup and restore are based on the in-house developed package ``dailybuandupdate``.

The system specific configuration file for ``daily_backup.sh`` should be placed in 
[``/usr/local/etc/daily_backup.cfg``](daily_backup.cfg).

A copy of the README from the daily restore procedure is shown below. Notice, that
we store the backup archive and restore procedure on an internal backup hub,
not just kept on the host itself. You should to the same.


```


                           Thursday 09 February 2017 at 18:28 CET

This documentation is compiled  as part of the  backup procedure.
The latest version of this text is stored in
	/var/CPbackup//RESTORE_INFORMATION
on the machine ddps.

If you are reading this file chances are that this machine has to
be restored after a major crash. Well, such is life.

First,  A word of WARNING:  The next check list does not claim to
be exhaustive,  error free, user friendly, or complete.  There is
most probably something that I forgot to put in it or things that 
have been modified on the system since this list was made.  
So please make use of discretion while using it.

The README is accompanied with theese documents:
 1  ../<hostname>.<uname>.<date>.<time>.tgz ...
    The OS backup archive(s). Use the latest.
 3  lshw.txt
    Output from the command lshw describing the hardware.
 4  motd
    copy of /etc/motd usually a description of the hosts purpose.
	but only if found.
 5  sysctl-a
    Output from sysctl -a -- the system configuration.
 6  archive_list
    List of all backup archives.
 7  status
    Status of the latest backup (good or bad).
 8  pkg_info
    List of all installed packages, usefull for restore.
 9  pkgs_manual.lst
    Manual installed packages, usefull for restore.
10  pkgs_auto.lst
    Automatic installed packages, usefull for restore.
11  The directory /var/CPbackup//RESTORE_INFORMATION/apt with everything
    required for restoring all packages installed with apt-get ... 
    on the failed system, including a ready made restore script.

Hardware
The failed system was running on this hardware - see lshw.txt for
details.
-----------------------------------------------------------------
hardware:  x86_64
              total        used        free      shared  buff/cache   available
Mem:            992          73         121          35         797         698
Swap:          1021           5        1016
MemTotal:        1016200 kB
-----------------------------------------------------------------

Operating system information (/etc/lsb-release)
-----------------------------------------------------------------
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04.2 LTS"
-----------------------------------------------------------------

Disk information below:
-----------------------------------------------------------------
df -hi:

Filesystem     Inodes IUsed IFree IUse% Mounted on
udev             120K   441  119K    1% /dev
tmpfs            125K   631  124K    1% /run
/dev/sda1        2,0M  108K  1,9M    6% /
tmpfs            125K     3  125K    1% /dev/shm
tmpfs            125K     3  125K    1% /run/lock
tmpfs            125K    16  125K    1% /sys/fs/cgroup
tmpfs            125K     4  125K    1% /run/user/1000
tmpfs            125K     4  125K    1% /run/user/0
-----------------------------------------------------------------
fdisk -l /dev/sda:

Disk /dev/sda: 32 GiB, 34359738368 bytes, 67108864 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xbbec7459

Device     Boot    Start      End  Sectors  Size Id Type
/dev/sda1  *        2048 65011711 65009664   31G 83 Linux
/dev/sda2       65013758 67106815  2093058 1022M  5 Extended
/dev/sda5       65013760 67106815  2093056 1022M 82 Linux swap / Solaris
-----------------------------------------------------------------

The list of all installed packages (pkg_info) has  been  compiled
with the commands
	/usr/bin/dpkg --get-selections >	\
		/var/CPbackup//RESTORE_INFORMATION/pkg_info
	/usr/bin/apt-mark showauto     >	\
		/var/CPbackup//RESTORE_INFORMATION/pkgs_auto.lst
	/usr/bin/apt-mark showmanual   >	\
		/var/CPbackup//RESTORE_INFORMATION/pkgs_manual.lst

Restore system information
--------------------------
 1  Install the same version of the OS, with the same patch level.
    See the wiki on how specific packages was installed, if any.

 2  Package re-installation:

	2.1 Easy
	The script apt-restore.sh in /var/CPbackup//RESTORE_INFORMATION/apt will
	restore all apt-get intalled packages to their original
	version. Either edit it (it is less than 20 lines) or run
	it from /var/CPbackup//RESTORE_INFORMATION/apt

	2.2 Alternative 1
    The file pkg_info can be used to re-install all packages this
    way:

        dpkg --set-selections < pkg_info
	    apt-get -y update
	    apt-get dselect-upgrade
        apt-get autoremove

	2.3 Altarnative 2
    The packages can be retored with the commands

        apt-mark auto $(cat pkgs_auto.lst)
        apt-mark manual $(cat pkgs_manual.lst)

3	Copy the latest (good) OS backup  to the new host and extract
    the files in /var/tmp.
	Move the configuration files to their place(s),  while taking
	care not to clubber e.g. device name information in /etc

4   Reboot in order to see if there are any OS specific problems.
    A known problem with Linux/Ubuntu is the automatic change of
	netcard devicename from e.g. eth0 to eht1.
	Change NAME="eth1" to eth0 in
        /etc/udev/rules.d/70-persistent-net.rules
	and delete any lines containing eth0. Next edit
        /etc/network/interfaces
	and replace eth1 with eth0. Then run the two commands
	    udevadm trigger
		/etc/init.d/networking restart

Restore postgres database
-------------------------
It is important that you have followed the above procedure before
restoring the database

First make sure that /etc/postgresql/9.x/main/pg_hba.conf has
the line

	local   all             postgres                                peer

and not

	local   all             postgres                                password

in order to do a postgres backup without passwords.

Also make sure /usr/local/bin/autopgsqlbackup is installed (is on the backup).

Now for the postgress restore:

You can restore from /var/CPbackup//RESTORE_INFORMATION/postgres-backup/ 
or /var/backups/postgres.

The official description is at http://www.postgresql.org/docs/9.1/static/backup.html

Notice that /var/CPbackup//RESTORE_INFORMATION/postgres-backup
are backups without OID's (pg_dump -Fc) and the same is true for 
/var/backups/postgres/{daily,monthly,weekly}

Retore is done as the user postgres with the command:

	pg_restore -d dbname filename

e.g.:

	pg_restore -d libreplan /var/CPbackup/postgres-backup/libreplan_12-04-2016

Two full backups are made with and without OIDs. They are placed
in /var/backups/postgres and is on the backup.

Restore a full backup is done this way as the user postgres:

	psql -f infile postgres

e.g.

	gunzip -c dumpall-with-oids.gz
	psql -f dumpall-with-oids postgres

It is yet not known if libreplan uses UIDs or not.

```

### Workflow

Each developer is responsible their code, preferably using git.

### NTHs STATUS for db2dps.pl

  - announces icmp, tcp and udp BGP rules correctly but lacks fragments, IP rules etc.
  - does _not annonces destination prefixes outside our scope_ (looks up network in network)
  - apt based perl module installation described
  - fast enough, most parameters comfigurable in either database or config file
  - runs as a background daemon started by systemd

### NTHs TODO
 - install GUI in /opt/ddps-ui/
 - enhancements:
   - solve overlapping rules
   - work with whitelists
   - fix for ssh blocking in perl
     - maybe an _impossible_ flag in the status section of the rules?
