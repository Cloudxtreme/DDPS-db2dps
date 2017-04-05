# Markdown pseudo code for db2dps

 ``db2dps`` is a small daemon running on the database server.

## Usage:

 ``db2dps`` [**-V**] [**-v**] [**-d**] [**-s** _seconds_]

  - **-v**: verbose and run in foreground
  - **-d**: daemonize
  - **-s** _seconds_: sleep time between database scan. Default is 20 seconds

 ``db2dps`` is stated from ``/etc/init.d``.

 Pseudo code:

```bash
{
   read configuration || fail
   check args: print version and exit | daemonize | run in foreground

   connect to database || exit fail

   while true; # continue loop starts here
   {
      if [ exit reqired ]
      {
         break loop
            close database connection
            exit normal
      }
       else {
         sleep except seconds on first loop
      }

      mkrulebase("annonce", all bgp hosts)
      {
         query for NOT isactivated and NOT expired records || query for all records || continue
         convert all records to rules usable by bgp
         send rulebase to each bgp host || warn
         # notice this may block if nothing listens on named pipe on receiver
      }
      set isactivated for announced rules in database

      mkrulebase("withdraw", all bgp hosts)
      {
         query for expired rules
         convert all records to rules usable by bgp
         send rulebase to each bgp host || warn
         # notice this may block if nothing listens on named pipe on receiver
      }
      set isexpired for withdrawn rules in database
   }

   close database connection and exit normal
}

```
## Requirements:
      sudo apt-get install libnet-openssh-compat-perl liblist-moreutils-perl
      apt-get install libnet-openssh-compat-perl
      apt-get -y install libnet-ssh2-perl libproc-daemon-perl
      apt -y install libnetaddr-ip-perl libtypes-path-tiny-perl
## Current version:
./db2dps -V
