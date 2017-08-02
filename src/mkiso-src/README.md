
# Start

## How to bootstrap all hosts in DDPS

All hosts are currently based on Ubuntu 16.04, the development environment is
[virtualbox](https://www.virtualbox.org/wiki/VirtualBox), while the production
environment is both virtual and physical.

Each host is created by booting an ISO image which will install everything
unattended for both the database/web server and the fastnetmon instances.

The ISO images are made with an modified version of
[ubuntu-server-auto-install](https://github.com/makelinux/ubuntu-server-auto-install).

You will have to crate the images, which is done the following way. Once you
have the database saver installed further ISO creations can be done there.

Working with ISO images makes the process more independent of e.g. ansible,
chef and other software configuration management systems. The ISO boots on
most hardware including ESXi and Virtual Box.

A bootstrap from scratch requires the following - once you have the database server
installed the creation of images can be made there.

  - Create an 16.04.2 server similar to the hardware made by
    [mk-ddps-dev-hw.sh](mk-ddps-dev-hw.sh) and install the
	packages `mkisofs`, `curl` and `build-essential`:

        apt-get -y install mkisofs curl build-essential

Then build the ISO images for the `ddps` and `fnm` servers:

		/opt/mkiso/bin/mkautoiso -u 16.04 -s ddps
		/opt/mkiso/bin/mkautoiso -u 16.04 -s fnm

The iso image will be stored in `/tmp` on the virtual host, Copy to a place
where the image can be read. If you use
virtualbox](https://www.virtualbox.org/wiki/VirtualBox), please look at
the script `./mk-ddps-dev-hw.sh` and edit accordingly.

Notice, that the 10Gb drivers on `fnm` is installed and may prevent the host
from working correctly under
virtualbox](https://www.virtualbox.org/wiki/VirtualBox),

The first server is no longer needed. Updates to `mkiso` and `ddps` may
be installed with the command starting in the source directory for each
package:

        ./remote.sh -v make install

Please edit `Makefile` before doing so; the destination IP address and login
user is placed at the top of the file.

