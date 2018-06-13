#! /usr/bin/env bash
#
# preinst
#  –   this script executes before that package will be unpacked from its Debian
#      archive (“.deb”) file. Many ‘preinst’ scripts stop services for packages
#      which are being upgraded until their installation or upgrade is completed
#      (following the successful execution of the ‘postinst’ script).
#
# postinst
#  –   this script typically completes any required configuration of the package
#      foo once it has been unpacked from its Debian archive (“.deb”) file.  Often
#      ‘postinst’ scripts ask the user for input, and/or warn the user that if
#      they accept the default values, they should remember to go back and
#      re-configure that package as the situation warrants. Many ‘postinst’
#      scripts then execute any commands necessary to start or restart a service
#      once a new package has been installed or upgraded.
#
# prerm
#  –   this script typically stops any daemons which are associated with a
#      package. It is executed before the removal of files associated with the
#      package.
#
# postrm
#  –   this script typically modifies links or other files associated with
#     foo, and/or removes files created by the package.

# preinst (optional, chmod 0755)        ?
# postinst (optional, chmod 0755)       ? service start, enable
# prerm (optional, chmod 0755)          ? service stop ...
# postrm (optional, chmod 0755)         ? service disable ...


project=db2dps
db2dps_service_file=db2dps.service
db2fnm_service_file=db2fnm.service

git_sha=`git rev-parse HEAD 2>/dev/null`
build_date=`date +"%Y-%m-%d %H:%M"`
VERSION=`git tag 2>/dev/null | sort -n -t'-' -k2,2 | tail -1`

if [ -z "$VERSION" ]; then
    VERSION="1.0-1"
fi

major_version=`echo ${VERSION} | awk -F'.' '$1 ~ /^[0-9]+$/ { print $1 }'`
minor_version=`echo ${VERSION} | sed 's/^.*\.//; s/-.*//' | awk '$1 ~ /^[0-9]+$/ { print $1 }'`
package_revision=`echo ${VERSION} | awk -F'-' '$NF ~ /^[0-9]+$/ { print $NF }'`

package=${project}_${major_version}.${minor_version}-${package_revision}

prefix=$package

test -d ${prefix}/DEBIAN || mkdir -p ${prefix}/DEBIAN

cat << EOF > ${prefix}/DEBIAN/control
Package: ${project}
Version: ${major_version}.${minor_version}-${package_revision}
Section: base
Priority: optional
Architecture: all
Depends: libnet-openssh-compat-perl, liblist-moreutils-perl, libnet-openssh-compat-perl, libnet-ssh2-perl, libproc-daemon-perl, libnetaddr-ip-perl, libdbi-perl, libdbd-pg-perl, libtypes-path-tiny-perl, libnetaddr-ip-perl, libtypes-path-tiny-perl, libnet-sftp-foreign-perl, libnet-openssh-perl, jq 
Maintainer: Niels Thomas Haugård <ntha@dtu.dk>
Description: Two scripts to force backup and software update on debian and ubuntu
EOF

# Depends: libnet-openssh-compat-perl

cat << EOF > ${prefix}/DEBIAN/postinst
cat << 'END_OF_SERVICE_FILE' > /etc/systemd/system/${db2dps_service_file}
[Unit]
Description=Regular background program processing daemon
After=syslog.target network.target postgresql.service

[Service]
Type=forking
ExecStart=/opt/db2dps/etc/init.d/db2dpsrc start
ExecStop=/opt/db2dps/etc/init.d/db2dpsrc stop

ExecReload=/opt/db2dps/etc/init.d/db2dpsrc reload

Restart=always

[Install]
WantedBy=multi-user.target

END_OF_SERVICE_FILE
sudo systemctl enable ${db2dps_service_file}
# sudo systemctl start ${db2dps_service_file}

cat << 'END_OF_SERVICE_FILE' > /etc/systemd/system/${db2fnm_service_file}
[Unit]
Description=Regular background program processing daemon
After=syslog.target network.target postgresql.service

[Service]
Type=simple
ExecStart=/opt/db2dps/etc/init.d/db2fnm start
ExecStop=/opt/db2dps/etc/init.d/db2fnm stop

ExecReload=/opt/db2dps/etc/init.d/db2fnm reload

Restart=always

[Install]
WantedBy=multi-user.target
END_OF_SERVICE_FILE
EOF

cat << EOF > ${prefix}/DEBIAN/preinst
if systemctl is-active db2dps.service|grep active; then
    echo systemctl stop ${db2dps_service_file}
fi

EOF

cat << EOF > ${prefix}/DEBIAN/prerm
sudo systemctl stop ${db2dps_service_file}
sudo systemctl stop ${db2fnm_service_file}
EOF

cat << EOF > ${prefix}/DEBIAN/postrm
sudo systemctl stop ${db2dps_service_file}
sudo systemctl disable ${db2dps_service_file}
sudo rm -f /etc/systemd/system/multi-user.target.wants/${db2dps_service_file} /etc/systemd/system/${db2dps_service_file}

sudo systemctl stop ${db2fnm_service_file}
sudo systemctl disable ${db2fnm_service_file}
sudo rm -f /etc/systemd/system/multi-user.target.wants/${db2fnm_service_file} /etc/systemd/system/${db2fnm_service_file}

sudo systemctl daemon-reload
sudo systemctl reset-failed
EOF

chmod 755 ${prefix}/DEBIAN/postinst ${prefix}/DEBIAN/prerm ${prefix}/DEBIAN/postrm ${prefix}/DEBIAN/preinst

# cd ${prefix}/DEBIAN/
# echo *

