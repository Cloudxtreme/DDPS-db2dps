#
# NTHA 2016
# 

# git versions made by make-version.sh
#include version_makefile

major_version=1
minor_version=0
package_revision=0

git_sha				= $(shell git rev-parse HEAD 2>/dev/null)
build_date			= $(shell date +"%Y-%m-%d %H:%M")

VERSION				= $(shell git tag 2>/dev/null | sort -n -t'-' -k2,2 | tail -1 )

# may/may not solve first run with no git tag
ifeq ($(strip $(VERSION)),)
VERSION = "1.0-1"
endif

# here be dragons: seems like $NF, $1 etc is not acceptable in $(shell ... which exclude awk and reduces sed match capab.
package_revision    = $(shell echo ${VERSION} | sed 's/^.*-//' )
major_version       = $(shell echo ${VERSION} | sed 's/\..*//')
minor_version       = $(shell echo ${VERSION} | sed 's/^.*\.//; s/-.*//')

project				= db2dps
# <project>_<major version>.<minor version>-<package revision>

package				= ${project}_${major_version}.${minor_version}-${package_revision}
prefix				= "/opt/${project}"

libfiles			= sqlstr.pm
etcfiles			= db2dps.service db2dpsrc db.ini.example fnmcfg.ini
inifiles			= db2dpsrc db2fnm
binfiles			= db2dps ddpsrules apply-default-rules kill_switch_restart_all_exabgp fnmcfg
# careful: binfiles (without extension) will be removed by clean target

configs				= configs/add_new_fastnetmon.sql.SH configs/change_fastnetmon_parameters.sql.SH configs/fastnetmon.conf.SH configs/fnm2db.ini.SH configs/import.sql.SH configs/influxd.conf configs/networks_list.SH configs/networks_whitelist.SH configs/postbootstrap.sh configs/rc.conf.SH


pkg: dirs Makefile version_make
	@echo "version: ${VERSION}"
	@echo "major_version: $(major_version)"
	@echo "minor_version: $(minor_version)"
	@echo "package_revision : $(package_revision)"
	@bash mk-debian-control-files.sh
	@$(MAKE) files
	@sudo dpkg-deb --build ${package}
	@echo "Install with:"
	@echo "apt-get install -y `dpkg -I ${package}.deb |sed '/Depends:/!d; s/Depends://; s/,//g'`"
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
	echo "installing ${binfiles} ..."
	sudo install -m 555 -g 0 -o 0 $(binfiles)	${package}/${prefix}/bin/
	echo "installing ${libfiles} ..."
	sudo install -m 444 -g 0 -o 0 $(libfiles)	${package}/${prefix}/lib/
	echo "installing ${etcfiles} ..."
	sudo install -m 555 -g 0 -o 0 $(etcfiles)	${package}/${prefix}/etc/
	echo "installing ${configs} ..."
	sudo install -m 444 -g 0 -o 0 $(configs)	${package}/${prefix}/etc/configs/
	echo "installing ${inifiles} ..."
	sudo install -m 555 -g 0 -o 0 $(inifiles)  ${package}/${prefix}/etc/init.d/

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

version_make:
	bash make-version.sh


# pkgs		= mkisofs curl libdata-dumper-simple-perl

# [Disable implied rules](http://stackoverflow.com/questions/4122831/disable-make-builtin-rules-and-variables-from-inside-the-make-file)
# as ``make db2dps`` will create ``db2dps`` from ``db2dps.sh``, cat db2dps.sh >db2dps, chmod a+x db2dps
.SUFFIXES:

.SILENT:

