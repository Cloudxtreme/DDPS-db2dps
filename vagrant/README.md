
# Readme

Quick start of DDPS using vagrant / virtualbox:

## Objectives

Either:

    - create a ISO build environment: `vagrant --do=onlyiso up`
    - create a live environment for testing and pkg-building: `vagrant --do=live up`
 
Using `onlyiso` will create an unattended boot ISO image for DDPS. Using `live` will
create a Ubuntu 16 box with everything installed.

TODO:
    - API + UI code here too.

# Missing

  - `/opt/db2dps/etc/db.ini`: See `db.ini.example`
  - `/opt/db2dps/etc/ssh/id_rsa`: keys for access to localhost/exabgp host
  - `/opt/db2dps/etc/fnmcfg.ini`: see fnmcfg.ini.example`

Also the database has not been initialized nor has pgpool2 been configured. You have
two options:

  - add example and test data which will show how the application is working
  - restore a configuration from backup (DeIC only)

Adding example data may be done with the command

    /root/files/apply_demo_data.sh

While restoring a configuration may be done as described in README_RESTORE for
`daily_backup.sh`.

