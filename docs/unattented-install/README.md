
# Start

The development environment is based on
[virtualbox](https://www.virtualbox.org/wiki/VirtualBox). Create an 16.04.2
server similar to the hardware made by [mk-ddps-dev-hw.sh](mk-ddps-dev-hw.sh)
with sshd enabled and `mkisofs` installed.

# How to create the installation environment

Clone `https://github.com/makelinux/ubuntu-server-auto-install.git`, make your
modifications; I've changed so these lines will be added to `ks.preseed`:

        d-i pkgsel/include string openssh-server wget
        d-i preseed/late_command string cp -a /cdrom/preseed/first-time-boot.sh /target/root; sed -i 's_exit 0_sh /root/first-time-boot.sh_' /target/etc/rc.local;

And added a similar line to the function `kickstart-cfg()`: (change path)

         /home/uninth/first-time-boot.sh $1/preseed/first-time-boot.sh

Now run `ks.preseed 16.04` to build a custom boot image.

# How to install the development environment

  - Run mk-ddps-dev-hw.sh (will remove existing ddps-dev!)
  - copy files with rsync.sh to `/var/tmp/install`, login and execute
    `cd /var/tmp/install; ./install.sh -v`

Your development environment should now be up and running.

