
# DeIC DPS: database server installation 

This document describes the installation of the _development_, _test_ and _production_
database host.

All hosts are based on [Ubuntu Server 16.04.2
LTS](https://wiki.ubuntu.com/XenialXerus/ReleaseNotes) installed on virtual
hardware. Install the ssh server during the initial install and do not select
automatic update.

Development and test are installed on 10Gb disks while the production host has
a larger disk.

The development and test hosts has two interfaces, one host-only the other
behind NAT. This makes connecting from the development environment more
consistent while still allowing internet access for software installation and
update.

**Please install your public ssh keys on a user before executing the script - the sshd configuration is changed to no prevent password based login.**

Copy the content of `cfg`, `db`, `deb` and the script `install.sh` to the host
after the basic installation. Then execute `install.sh` as `root`.

	 rsync -avzH cfg db deb dev.lst install.sh username@ddps-dev:/var/tmp/install/ 
	 ssh username@ddps-dev
	 cd /var/tmp/install
	 sudo ./install.sh -v

You may run the script as many times as you like; you can install but not
uninstall. The script is supposed to do the following:

  1. Install 3 internal developed packages. Only `dailybuandupdate` is required
	 outside our  test environment; it  is used for patching and backup. You
	 may decide not to install the other packages.
  2. The system is patched and may reboot if required. If so, login once more
	 and execute `./install.sh` as `root`.
  3. If you have a list of developers, place username, full name and userid in
	 the file `dev.lst` separated by ';'. The file is ignored if it doesn't exist.
  4. No users should have password login with ssh, so the ssh config file is
	 modified accordingly. Also, see the `adduser` and `usermod` commands; they
	 are required for password less login when users doesn't have a password.
  5. Fastnetmon uploads rule files with `sftp`, a user `newrules` and group
	 `sftpusers` is created and a dummy ssh-ed25519 key is added to
	 `authorized_keys`. Notice the use of `chattr +i` and ownership of the
	 users home directory.
  6. Postgres is installed from `apt.postgresql.org` and the latest
	 `pg_hba.conf` is changed.
  7. The database schema's is created based on a schema dump; this will print
	 warnings etc. as the different dumps contain redundant information. The
	 warnings can safely be ignored.
  8. Backup and restore: See `/var/CPbackup/RESTORE_INFORMATION/README`, the
	 directory may be collected on a daily basis with e.g. `rsync`


### Apache / NGINX configuration

<yellownote>TODO:</yellownote>

### Node.js

<yellownote>TODO:</yellownote>

Where to go next: See the [installation of the daemon db2dps](db2dps-documentation.md)

