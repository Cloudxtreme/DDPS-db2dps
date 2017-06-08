
# DDPS database host installation

The following describes the _database host_ and the daemon which adds and
queries the database for new and expired rules. The documentation is 
described here:

  - [Installation and configuration of the database host](ddps-database-server-installation.md)
  - [Installation and configuration of the database daemon db2dps](db2dps-documentation.md)
  - [Short design overview](ddps-design-short.md)

## Configuration

The configuration file is `/opt/i2dps/etc/db.ini`, change the following as needed:

Under _[general]_ set / change _dbpassword_ and edit _ournetworks_ to match all your networks.
The daemon will not issue announce / withdraw commands for addresses outside these net.

The _sleep_time_ is default 10 seconds and the database is polled this interval for changes.
Please check _rolconnlimit_ in [pg_roles](https://www.postgresql.org/docs/current/static/view-pg-roles.html)
before you lower the value.

While the configuration file mention black hole communities it is not yet supported.

Last change _hostlist_ to match your exabgp hosts, and for each host specify how to connect.

