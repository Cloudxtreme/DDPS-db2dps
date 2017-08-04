
# Installation

## Introduction 

This installation procedure will work on both physical and virtual self hosted
hardware. The hosts are created unattended by booting from an ISO image.

The image has to be created ahead of the installation and is described below.

Working with ISO images enables the installation of FastNetMon on off site
equipment and doesn't require infrastructure systems like Ansible or Chef.  The
ISO images enables installation on most hyper visors like esx and Virtual Box.

All DDPS hosts are currently based on Ubuntu 16.04, the development environment is
[virtualbox](https://www.virtualbox.org/wiki/VirtualBox), while the production
environment is both virtual and physical.

Each host is created by booting an ISO image which will install everything
unattended for both the database/web server and the fastnetmon instances.

The ISO images are made with an modified version of
[ubuntu-server-auto-install](https://github.com/makelinux/ubuntu-server-auto-install).

## Build instruction

The following procedure is written for
[virtualbox](https://www.virtualbox.org/wiki/VirtualBox) on OS X or Linux. 

Notice, that in a virtual box environment where the guest OS should be both
behind NAT and be accessible with SSH from the host OS the Virtual machine must
have two NIC's. Also notice that internet access is required from the guest OS
for software installation and updates.

### First boot image

The first host is just for creating the ISO images for the DDPS server; once
it has been created new ISO images may be made there.

  - Create an 16.04.2 64 bit server with 2 NIC's, 10Gb disk and 512Mb RAM,
    similar to the hardware made by
    [mkvbox.sh](../src/mkiso-src/mkvbox.sh).
  
  - Install the packages `mkisofs`, `curl` and `build-essential`:

        apt-get -y install mkisofs curl build-essential

  - In [../src/mkiso-src](../src/mkiso-src) edit `Makefile` and change
    the IP address and login user to match your now Guest OS (`TARGETHOST = ... `)
	and
	execute

        ./remote.sh -v make install

You should now be able to build ISO images for all hosts with the command

		/opt/mkiso/bin/mkiso -u 16.04 -s HOSTNAME

This host is no longer needed once the DDPS host has been made, but copy the
changed configuration files for `mkiso` to `ddps` before deleting the guest OS.

### Building the ISO for DDPS

Edit the following before creating the ISO file for `ddps`

 - Replace `/opt/mkiso/common/authorized_keys` with your `authorized_keys`
 - Edit `/opt/mkiso/specific/ddps/host.config` and change the name and password
   for the login user. Use host.config.template as a template.
 - Edit `/opt/mkiso/specific/ddps/install.d/1_add-interface-cfg.sh` and change
   the IP configuration at the top to match the _host only_ interface. 
 - Edit `/opt/mkiso/specific/ddps/data/dev.lst` and add your developers. They
   will have to provide ssh public keys as their accounts will be created
   locked.  If the file is missing no developers will be added during
   installation.
 
Building the ISO for booting the host `ddps` is done this way:

		/opt/mkiso/bin/mkiso -u 16.04 -s ddps

The ISO image will be stored in `/tmp` on the Guest OS, Copy to a place
where the image can be read.

Boot the ISO on similar hardware and you should have a working DDPS server.

Install the software (`mkiso` and `db2dps`) the same way as above:

Edit `Makefile` in `mkiso-src` and `db2dps-src`  and execute

	./remote.sh -v make install

See the [README for ddps](../src/ddps-src/README.md) on configuration.

### Building the ISO for FastNetMon

TODO:

Notice, that the 10Gb drivers on `fnm` is installed and may prevent the host
from working correctly under
virtualbox](https://www.virtualbox.org/wiki/VirtualBox),


## Final note about creating ISO images

Building the boot image for the database server takes about 30 seconds first time
mainly download time of the Ubuntu 16.04 image. Creating the boot image after
download takes just less than 10 seconds.

First time with a valid `host.config`:

	time /opt/mkiso/bin/mkautoiso -u 16.04 -s ddps
	--2017-08-04 14:59:25--  http://releases.ubuntu.com/16.04/ubuntu-16.04.3-server-amd64.iso
	Resolving releases.ubuntu.com (releases.ubuntu.com)... 91.189.88.23, 2001:67c:1560:8001::7
	Connecting to releases.ubuntu.com (releases.ubuntu.com)|91.189.88.23|:80... connected.
	HTTP request sent, awaiting response... 200 OK
	Length: 865075200 (825M) [application/x-iso9660-image]
	Saving to: ‘/opt/mkiso//downloads/ubuntu-16.04.3-server-amd64.iso’

	ubuntu-16.04.3-server-amd64.iso              100%[==> .... ] 825.00M  55.7MB/s    in 17s

	2017-08-04 14:59:42 (49.7 MB/s) - ‘/opt/mkiso//downloads/ubuntu-16.04.3-server-amd64.iso’ saved [865075200/865075200]

	Ubuntu-Server 16.04.3 LTS "Xenial Xerus" - Release amd64 (20170801)
	created /tmp/ubuntu-16.04.3-server-amd64-auto-install.ddps.iso

	real	0m27.448s
	user	0m0.820s
	sys	0m6.760s

Not so bad.

	time /opt/mkiso/bin/mkautoiso -u 16.04 -s ddps
	Ubuntu-Server 16.04.3 LTS "Xenial Xerus" - Release amd64 (20170801)
	created /tmp/ubuntu-16.04.3-server-amd64-auto-install.ddps.iso

	real	0m9.790s
	user	0m0.492s
	sys	0m2.628s

Better.

