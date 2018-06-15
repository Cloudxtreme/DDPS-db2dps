#
# INI style configuration file for db2dps
# Quote strings which contain ';'

[general]

# access to postgress database on localhost
dbuser              = $dbusr
dbpassword          = $dbpass
dbname              = $dbname

# all our networks
ournetworks         = $ournetworks

# name of exabgp instances requiring a full bgp flow will show up here
datadir             = /opt/db2dps/data

# new rules will be uploaded from fastnetmon with sftp to here
newrulesdir         = /home/sftpgroup/newrules/upload

# exit nicely if this file exist
shutdown            = /tmp/.shutdown_now

# seconds between database read
sleep_time          = 10

# rulebase - print all rules to this file; will be transfered to BGP host later
rulebase            = /opt/db2dps/tmp/rulebase.txt

# template strings for blackhole and reatelimit
blackhole           = route %s next-hop black.hole.ip.addr community [65001:666 65001:400];
ratelimit           = route %s next-hop rate.limit.ip.addr community [65001:666];

# template strings for un-blackhole and reatelimit
unblackhole         = route delete %s next-hop black.hole.ip.addr community [65001:666 65001:400];
unratelimit         = route delete %s next-hop rate.limit.ip.addr community [65001:666];

# exabgp hostnames - ''general'' is reserved by design, sorry. hostname, sshuser and identy_file self explaining
# filtertype: how does this exabgp enforce rules: flowspec | blackhole or | ratelimit - the command strings will be taken
# from the templates above. Exabgp communicates wia a named pipe; the template string is echo'ed after substitution
# of % .. has taken place

# we use pgpool2 in production, but for testing we only have one system
clustermembers  = localhost

hostlist   = localhost

[localhost]
hostname        = localhost
sshuser         = root
identity_file   = /opt/db2dps/etc/ssh/id_rsa
public_key      = /opt/db2dps/etc/ssh/id_rsa.pub
filtertype      = flowspec
exabgp_pipe     = /run/exabgp/exabgp.cmd

[ddpsrules]

customerid              = $customerid
fastnetmoninstanceid    = $fastnetmoninstanceid
uuid                    = ddpsrules-cli-adm
administratorid         = $fastnetmoninstanceid
blocktime               = 10
