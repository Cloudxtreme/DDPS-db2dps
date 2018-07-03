
# Readme

Quick start of DDPS using vagrant / virtualbox:

  - [how to install vagrant and virtualbox on OS X](https://gist.github.com/rrgrs/9258511)
  - [Vagrant – Getting Started on macOS](https://coolestguidesontheplanet.com/vagrant-getting-started-on-macos/)

If the installation fail see [README-highsierra.md](./README-highsierra.md).

## Objectives

Once vagrant and virtualbox has been installed, it is possible to play with the
software and use it for live demo and development. It is also possible to
create a bootable CD for installation on VMware, or replace the vagrant up test
data with a copy of the production data.

Start with updating the box image

  - `vagrant box update`         
  - **create a live test environment with test data:** from `test-data/vars.SH`:          
    `SHELL_ARGS=LIVE_TESTDATA vagrant --provision up`
  - create a ISO build environment:           
    `SHELL_ARGS=MAKE_ISO vagrant --provision up`
  - create a live environment with restored live data:           
    `SHELL_ARGS=LIVE_RESTORED_DATA vagrant --provision up`

The ISO will be written to _vagrant_, while the test data is in `test-data`and
the restored data must be in `restored-data` which is not no git.

To test and see the installation process - and keep the installation log for
later, you may execute

````````bash
(
vagrant destroy -f
vagrant box update
SHELL_ARGS=LIVE_TESTDATA vagrant --provision up
) 2>&1 | tee -i installation-log.log
````````

Accessing the system may be done with

  - `vagrant ssh` - login as user `vagrant`; use `sudo bash` to obtain administrative rights 
  - Access to the web front end from a browser: `http://127.0.0.1:8080`
  - Access to the API from a browser: `http://127.0.0.1:9090`

# Limitations

The following limitations apply
**if you are not running with VPN towards our production environment**

  - The graphs in the web-gui is empty as there is no fastnetmon instances
    sending rules to the test system, nor is it possible to
    query any fastnetmon / influxd for network data.
  - There is no
    [looking glass](https://www.noction.com/blog/bgp-looking-glass-servers)
    server running (lg.TLD) and only one exabgp installed, so the `fnmcfg`
    fails to check if the announced rules are enforced.
  - Currently pgpool2 is not configured
  - Probably a lot of other thing I've forgot

