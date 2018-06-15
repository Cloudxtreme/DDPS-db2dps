
# Readme

Quick start of DDPS using vagrant / virtualbox:

  - [how to install vagrant and virtualbox on OS X](https://gist.github.com/rrgrs/9258511)
  - [Vagrant – Getting Started on macOS](https://coolestguidesontheplanet.com/vagrant-getting-started-on-macos/)

## Objectives

Once vagrant and virtualbox has been installed, it is possible to play with the
software and use it for live demo and development. It is also possible to
create a bootable CD for installation on VMware, or replace the vagrant up test
data with a copy of the production data.

  - **create a live test environment with test data:** from `test-data/vars.SH`:
    `SHELL_ARGS=LIVE_TESTDATA vagrant --provision up`
  - create a ISO build environment:
    `SHELL_ARGS=MAKE_ISO vagrant --provision up`
  - create a live environment with restored live data:
    `SHELL_ARGS=LIVE_RESTORED_DATA vagrant --provision up`

The ISO will be written to _vagrant_, while the test data is in `test-data`and
the restored data must be in `restored-data` which is not no git.
 
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
  - Probably a lot of other thing I've forgot

