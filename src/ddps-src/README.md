
# Build instructions

Install vagrant and virtualbox then follow the instructions in [README](../vagrant/README.md).

# db2dps

  - db2dps is a daemon which periodically queries the rule database for new
    rules, announces or withdraw them using two exabgp instances.
  - the requirements and installation procedure are described
    [here](../docs/ddps-database-server-installation.md).

## Usage
 
  ``db2dps [-V] [-v] [-d] [-s seconds]``
 
   - **-V**: print version information and exit
   - **-v**: verbose and run in foreground
   - **-d**: demonise
   - **-s** _seconds_: sleep time between database scan. Default is 20 seconds.
 
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

The `sleep_time` is by default 10 seconds and the database is polled this interval
for changes.  Please check `rolconnlimit` in
[pg_roles](https://www.postgresql.org/docs/current/static/view-pg-roles.html)
before you lower the value.

While the configuration file mentions black hole communities, it is not yet
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

If not then start it with:

	service db2dps start

#### Rule creation 

There is a set of command line tools for creating e.g. default rules that
matches a combination of [DDoS/DoS Attack Mitigation Best Common Operational
Practices](http://nabcop.org/index.php/DDoS-DoS-attack-BCOP) and [Akamai Q4
2016 state of the internet security
report](https://www.akamai.com/us/en/multimedia/documents/state-of-the-internet/q4-2016-state-of-the-internet-security-report.pdf)

Apply default rules with:

	apply-default-rules

See a short view of currently enforced rules with

	ddpsrules active

`ddpsrules` may be used for adding, deleting and printing current rules. See
`ddpsrules -h` for usage.

The rules which should go to exabgp is in `/tmp/destignation-append`.

##### Example rule creation

Block UDP fragments for 1 min from all to 95.128.24.0/21:

	ddpsrules add    --blocktime '1' --dst '95.128.24.0/21'    \
        --src 'null' --protocol 'udp'  --dport 'null'              \
        --sport 'null' --icmp_type 'null' --icmp_code 'null'       \
        --tcpflags 'null' --length 'null' --dscp 'null'            \
        --frag '[is-fragment first-fragment last-fragment]'        \
        --action 'discard'

Rate limit SNMP traffic

    ddpsrules add --blocktime '1' --dst '95.128.24.0/21'           \
                  --src 'null' --protocol '=udp'  --dport 'null'   \
                  --sport '=161 =162' --icmp_type 'null'           \
                  --icmp_code 'null'  --tcpflags 'null'            \
                  --length 'null' --dscp 'null' --frag 'null       \
                   --action 'rate-limit 9600'

Block chargen (tcp and udp)
                   
    ddpsrules add   --blocktime '1' --dst '95.128.24.0/21'          \
                    --src 'null' --protocol '=tcp =udp'             \
                    --dport 'null' --sport '=19' --icmp_type 'null' \
                    --icmp_code 'null'  --tcpflags 'null'           \
                    --length 'null' --dscp 'null' --frag 'null'     \
                    --action 'discard'

Block NTP amplification attacks; notice filtering on the source port

    ddpsrules add   --blocktime '1' --dst '95.128.24.0/21'  \
                    --src 'null' --protocol 'udp'  --dport 'null'   \
                    --sport '=123' --icmp_type 'null'               \
                    --icmp_code 'null'  --tcpflags 'null'           \
                    --length '=468' --dscp 'null' --frag 'null'     \
                    --action 'discard'

### View active rules

Active rules may be view'ed with

`````
ddpsrules active
-------------------------------------------------------------------------------------------------------------------------------------
| Connected to db netflow as dbadmin, Active rules                                                                                  |
-------------------------------------------------------------------------------------------------------------------------------------
 flowspecruleid   | dest. prefix     | src. prefix      | ipprotocol           | destinationport  | validto
-----------------+------------------+------------------+----------------------+------------------+-----------------------------------
 12483            | 95.128.24.0/21   | @Any             | udp                  | =123             | 2017-08-04 12:21:09.050498+02

`````

And the enforced rule (exabgp syntax) is show with

`````
sudo ddpsrules log
Aug 4 12:21:09 withdraw flow route 12483 { match { destination 95.128.24.0/21; srcordestport =123; destination-port =123; protocol udp; packet-length =468; } then { discard } } }

`````
Which also shows all historical rules (but only from `/var/log/syslog`).
`sudo` is required for read access to `/var/log/syslog`.

### Delete active rule

Rules are withdrawn by setting their expire time to `now()`.


`````
ddpsrules del 12483
flowspecruleid 12484 expires at 2017-08-04 12:24:24, in 0 seconds
db update freq is 10 seconds
`````

### Delete all active rules

All active rules may be deleted with:

    ddpsrules -v delall

<!-- ddpsrules del `ddpsrules active|awk ' $0 ~ /^-*$/ { next; }; $1 ~ /flowspecruleid/ { next; }; $1 ~ /^[-a-z0-9]+$/ { print $1 }'` -->

If everything else fails, a full reset of all announcements may be initiated

	kill_switch_restart_all_exabgp.pl
	
Which will restart the exabgp services.


