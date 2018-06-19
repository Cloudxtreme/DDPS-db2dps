#!/bin/bash
#
#  as /opt/mkiso is mounted the @argv thing here is more or less obsolite
#
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
export LANGUAGE=C
export LC_CTYPE=C

f_iso()
{
    echo "creating boot iso for ddps ... "
    f_patch

    # specific needs to be restored/cloned from our internal gitlab server
    # git clone ...
    # ln -s ...

    cd /opt/mkiso
    apt-get -y install genisoimage
    /opt/mkiso/bin/mkautoiso -u 16.04 -s ddps
    test -d /vagrant && mv /tmp/*iso /vagrant
}

f_ddps_live()
{
    echo "creating live environment for ddps ... "
    # testing ...
    ln -s /vagrant/files /root

    cd /root/files
    bash ./install.sh -v

    # ls  /mkiso-src/mkiso/common/* 
    #rsync -azH /mkiso-src/mkiso/specific/ddps/*	/root/files
    #rsync -azH /mkiso-src/mkiso/common/*	/root/files
    #/bin/rm -f	/root/files/install.d/6_install_go.sh	\
	#	/root/files/host.config			\
	#	/root/files/host.config.template
    #cd /root/files
}

function f_patch()
{
	apt-get -y update
	apt-get -y upgrade
	apt-get -y dist-upgrade

}

function f_install_test_data()
{
    cd /vagrant/test-data || {
        echo chdir /vagrant/test-data failed
        exit 0
    }
    bash /vagrant/test-data/apply_demo_data.sh
    cat <<-EOF
Vagrant:
    vagrant halt; vagrant up
*:
    reboot
EOF
}

echo "arguments: $*"

locale-gen en_GB.UTF-8
dpkg-reconfigure locales

case $* in 
    "") echo "nothing special to do ... "
        ;;
    MAKE_ISO)    f_iso
        ;;
    LIVE_TESTDATA)
                f_ddps_live
                f_install_test_data
        ;;
    LIVE_RESTORED_DATA)
                f_ddps_live
                # install restored data ...
        ;;
esac

exit 0

