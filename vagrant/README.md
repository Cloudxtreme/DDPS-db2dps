
# Readme

Quick start of DDPS using vagrant / virtualbox:

  - [how to install vagrant and virtualbox on OS X](https://gist.github.com/rrgrs/9258511)
  - [Vagrant – Getting Started on macOS](https://coolestguidesontheplanet.com/vagrant-getting-started-on-macos/)

## Objectives

Either:

  - create a ISO build environment:
    `SHELL_ARGS=MAKE_ISO vagrant --provision up`
  - create a live test environment with test data:
    `SHELL_ARGS=LIVE_TESTDATA vagrant --provision up`
  - create a live environment with restored live data:
    `SHELL_ARGS=LIVE_RESTORED_DATA vagrant --provision up`

The ISO will be written to '.', while the test data is in `test-data`and the
restored data must be in `restored-data` (not no git).
 
TODO:
    - NGINX, API + UI code here too.

# Limitations

  - The graphs in the web-gui is empty as there is no fastnetmon instances
    sending rules to the test system, nor is it possible to
    query any fastnetmon / influxd for network data.
  - There is no looking glass server running (lg.TLD) and only one exabgp
    installed, so the `fnmcfg` fails to check if the announced rules are
    enforced.
  - Currently pgpool2 is not configured
  - Probably something else but I've forgot

Example data is based on `./test-data/vars.SH`:

```````
case `uname` in
    Darwin) ipv4addr="10.0.2.15/24"
        ;;
    Linux) ipv4addr=`ip -o -4 addr| awk '$4 !~ /127.0.0.1/ { print $4 }'`
        ;;
esac

export dbusers="admin dbadmin flowuser postgres repuser"
export dbpass="password"
export dbusr="dbadmin"
export dbpass="password"
export dbname="netflow"
export ipv4addr="$ipv4addr"
export ipv4listenaddress="$ipv4addr"
export pcp_listen_addresses="$ipv4addr"
export backend_hostname0="$ipv4addr"
export backend_hostname1=""                  # not used
export sr_check_password="password"
export sr_check_database="netflow"
export default_uuid_administratorid="3611a271-50ae-4425-86c5-b58b04393242"
export bootstrap_ip="10.0.0.1"
export ournetworks="10.0.0.0/8 172.16.0.0/12"
export customerid="f561067e-10e3-44ed-ab12-9caed904d8d9"
export fastnetmoninstanceid="aac8c5a6-097b-4c0c-bbe6-fe6677ff7eac"
export uuid="ddpsrules-cli-adm"
export administratorid="$default_uuid_administratorid"
```````


