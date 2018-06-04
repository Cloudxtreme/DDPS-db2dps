#
# NTHA 2016
# 

# git versions made by make-version.sh
include version_makefile

project=db2dps
# <project>_<major version>.<minor version>-<package revision>

package=${project}_${major_version}.${minor_version}-${package_revision}
prefix="/opt/${project}"

libfiles = sqlstr.pm
etcfiles = db2dps.service db2dpsrc db.ini.example fnmcfg.ini
inifiles = db2dpsrc db2fnm
binfiles = db2dps ddpsrules apply-default-rules kill_switch_restart_all_exabgp fnmcfg
# careful: binfiles (without extension) will be removed by clean target
configs  = configs/add_new_fastnetmon.sql.SH configs/change_fastnetmon_parameters.sql.SH configs/fastnetmon.conf.SH configs/fnm2db.ini.SH configs/import.sql.SH configs/influxd.conf configs/networks_list.SH configs/networks_whitelist.SH configs/postbootstrap.sh configs/rc.conf.SH

all: dirs Makefile
	@bash mk-debian-control-files.sh
	@$(MAKE) files
	@dpkg-deb --build ${package} && echo "made $@"
	@echo "Install with:"
	@echo "apt-get install -y `dpkg -I *deb|sed '/Depends:/!d; s/Depends://; s/,//g'`"
	@echo "dpkg -i ${package}.deb"
	@echo "remove with apt-get remove ${package}"
	
dirs:
	@test -d ${package}/DEBIAN	|| mkdir -p ${package}/DEBIAN
	@test -d ${package}/${prefix}/bin		|| mkdir -p ${package}/${prefix}/bin
	@test -d ${package}/${prefix}/data		|| mkdir -p ${package}/${prefix}/data
	@test -d ${package}/${prefix}/lib		|| mkdir -p ${package}/${prefix}/lib
	@test -d ${package}/${prefix}/log		|| mkdir -p ${package}/${prefix}/log
	@test -d ${package}/${prefix}/tmp		|| mkdir -p ${package}/${prefix}/tmp
	@test -d ${package}/${prefix}/etc/ssh		|| mkdir -p ${package}/${prefix}/etc/ssh
	@test -d ${package}/${prefix}/etc/configs	|| mkdir -p ${package}/${prefix}/etc/configs
	@test -d ${package}/${prefix}/etc/init.d	|| mkdir -p ${package}/${prefix}/etc/init.d

files: $(binfiles)
	@install -m 555 -g root -o root $(binfiles)	${package}/${prefix}/bin/
	@install -m 444 -g root -o root $(libfiles)	${package}/${prefix}/lib/
	@install -m 555 -g root -o root $(etcfiles)	${package}/${prefix}/etc/
	@install -m 444 -g root -o root $(configs)	${package}/${prefix}/etc/configs/
	@install -m 555 -g root -o root $(inifiles)     ${package}/${prefix}/etc/init.d/

db2dps: db2dps.pl version.pm
	sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}' db2dps.pl > db2dps

ddpsrules: ddpsrules.pl version.pm
	sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}' ddpsrules.pl > ddpsrules

apply-default-rules: apply-default-rules.sh version.pm
	sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}' apply-default-rules.sh > apply-default-rules

kill_switch_restart_all_exabgp: kill_switch_restart_all_exabgp.pl version.pm
	sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}' kill_switch_restart_all_exabgp.pl > kill_switch_restart_all_exabgp

fnmcfg: fnmcfg.sh version.SH
	sed -e '/#INCLUDE_VERSION_SH/ {' -e 'r version.SH' -e 'd' -e'}'  fnmcfg.sh > fnmcfg

clean:
	rm -fr ${package} *.bak *.1 ${binfiles}

SERVICEFILE	= db2fnm.service


version.SH:
	bash ./mk-version.sh

version.pm:
	bash ./mk-version.sh

uninstall:
			echo remove everything below $(PREFIX)

# pkgs		= mkisofs curl libdata-dumper-simple-perl

# [Disable implied rules](http://stackoverflow.com/questions/4122831/disable-make-builtin-rules-and-variables-from-inside-the-make-file)
# as ``make db2dps`` will create ``db2dps`` from ``db2dps.sh``, cat db2dps.sh >db2dps, chmod a+x db2dps
.SUFFIXES:

.SILENT:

