
# Readme for db2dps, part of DDPS

  - db2dps is a daemon which periodically queries the rule database for new
    rules, announces or withdraw them using two exabgp instances.
  - the file [db2dps.c](db2dps.c) and [db2dps.pl](db2dps.pl) contains pseudo code usage.
  - the current version is written in Perl.
  - the requirements and installation procedure is described
    [here](../docs/ddps-database-server-installation.md).

The pseudo code for `db2dps` is:
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


