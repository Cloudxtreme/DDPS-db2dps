
# Start

## How to bootstrap the environment

All hosts are currently based on Ubuntu 16.04, the development environment is
[virtualbox](https://www.virtualbox.org/wiki/VirtualBox), while the production
environment is both virtual and physical.

The environment is created by booting an ISO image which will install everything
unattended for both the database/web server and the fastnetmon instances.

The ISO images are made with an modified version of
[ubuntu-server-auto-install](https://github.com/makelinux/ubuntu-server-auto-install).

A bootstrap from scratch requires the following - once you have the database server
installed the creation of images can be made there.


  - Create an 16.04.2 server similar to the hardware made by
   [mk-ddps-dev-hw.sh](mk-ddps-dev-hw.sh) with sshd enabled and `mkisofs`
   installed.

  - On the new hosts do
   `/opt/mkiso/bin/ .... `

The iso image will be stored in `/tmp`, copy to `${HOME}/VirtualBox VMs/iso` and execute
`./mk-ddps-dev-hw.sh` to bootstrap the first host.



