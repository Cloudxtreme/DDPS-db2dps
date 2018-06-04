#!/bin/bash
#
#  as /opt/mkiso is mounted the @argv thing here is more or less obsolite
#
export LC_ALL=C
export LANG=C
export LANGUAGE=C
export LC_CTYPE=C

f_iso()
{
    echo "creating boot iso for ddps ... "
    patch
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
#
    #cd /root/files
}

function patch()
{
	apt-get -y update
	apt-get -y upgrade
	apt-get -y dist-upgrade

}


function install_mkiso()
{
	echo
}

# main
echo "arguments: $*"

locale-gen en_GB.UTF-8

case $* in 
    "")     echo "nothing special to do ... "
        ;;
    onlyiso)    f_iso
        ;;
    live)       f_ddps_live
                # create a live environment prepared for either restore of our data
                # part 1: install software, tweak ssh etc. 
                # part 2: nothing or apply configurations: users, databse etc.
                # demo data: apply_demo_data.sh
                # restore: restore from daily_backup
        ;;
esac

exit 0


