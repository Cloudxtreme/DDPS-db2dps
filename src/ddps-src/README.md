
# db2dps

  - db2dps is a daemon which periodically queries the rule database for new
    rules, announces or withdraw them using two exabgp instances.
  - the requirements and installation procedure is described
    [here](../docs/ddps-database-server-installation.md).

## Usage
 
  ``db2dps [-V] [-v] [-d] [-s seconds]``
 
   - **-V**: print version information and exit
   - **-v**: verbose and run in foreground
   - **-d**: demonise
   - **-s** _seconds_: sleep time between database scan. Default is 20 seconds
 
## Description

The _initial configuration_ is kept in a _ini style_ configuration file. The
information includes

  - credentials for accessing the database
  - most / all used sql statements
  - path to directory for _rules uploaded by fastnetmon_ and directory where exabgp may create a semaphore file in case it requires a full bgp flow
  - path to semaphore file for controlled shutdown
  - sleep time
  - blackhole and reatelimit templates
  - sections / list of exabgp instances and how to access them
  - list of all internal networks for which there may be made destination rules

## Configuration

The configuration file is `/opt/i2dps/etc/db.ini`, change the following as
needed:

Under `[general]` set / change `dbpassword` and edit`ournetworks` to match all your networks.
The daemon will not issue announce / withdraw commands for addresses outside these net.

The `sleep_time` is default 10 seconds and the database is polled this interval
for changes.  Please check `rolconnlimit` in
[pg_roles](https://www.postgresql.org/docs/current/static/view-pg-roles.html)
before you lower the value.

While the configuration file mention black hole communities it is not yet
supported.

Last change `hostlist` to match your exabgp hosts, and for each host specify how to connect.

### Development and playground
If you do not have any exabgp hosts but would like to test software and see rules
created (but not enforced), then do this:

Create SSH RSA keys for the login user (`sysadm`):

	su - sysadm
	ssh-keygen -t rsa -b 4096

Do not use [`-o -a ... ` nor
ed25519](https://stribika.github.io/2015/01/04/secure-secure-shell.html) as
this may not be compatible with `libssh` used by the software.

Test ssh connectivity with

	su - sysadm
	ssh -v localhost
	exit

Next edit `db.ini` and set

	hostlist	= localhost

	[localhost]
	hostname        = localhost
	sshuser         = sysadm
	identity_file   = /home/sysadm/.ssh/id_rsa
	public_key      = /home/sysadm/.ssh/id_rsa.pub
	filtertype      = flowspec
	exabgp_pipe     = /tmp/destignation-append

You should be able to login. Check the software is started with

	service db2dps status

If not then start it with

	service db2dps start

#### Rule creation 

There is a set of command line tools for creating e.g. default rules that
matches a combination of [DDoS/DoS Attack Mitigation Best Common Operational
Practices](http://nabcop.org/index.php/DDoS-DoS-attack-BCOP) and [Akamai Q4
2016 state of the internet security
report](https://www.akamai.com/us/en/multimedia/documents/state-of-the-internet/q4-2016-state-of-the-internet-security-report.pdf)

Apply default rules with:

	/opt/db2dps/bin/apply-default-rules

See a short view of currently enforced rules with 

	/opt/db2dps/bin/ddpsrules active

`ddpsrules` may be used for adding, deleting and printing current rules. See
`ddpsrules -h` for usage.

The rules which should go to exabgp is in `/tmp/destignation-append`

All historical rules may be viewed with

	/opt/db2dps/bin/ddpsrules log

All active rules may be deleted with

	/opt/db2dps/bin/ddpsrules del `ddpsrules active|awk ' $1 ~ /^[0-9]+$/ { print $1 }'`

If everything else fails, a full reset of all announcements may be initiated
with

	/opt/db2dps/bin/kill_switch_restart_all_exabgp.pl

Which will restart the exabgp services.
