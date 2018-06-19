#!/bin/sh
#
# $Header$
#
#--------------------------------------------------------------------------------------#
# TODO
#
#--------------------------------------------------------------------------------------#

TMPFILE=`tempfile`

export DEBIAN_FRONTEND=noninteractive

function install_exabgp()
{
    echo "$0: installing exabgp and socat .... "
    apt-get -y install exabgp socat  >$TMPFILE
    case $? in
        0)  echo "done"
            ;;
        *)  echo "failed:"
            cat $TMPFILE
            ;;
    esac

    echo "$0: applying tmpfile configs ... "
    echo 'd /var/run/exabgp 0755 exabgp exabgp -' > /usr/lib/tmpfiles.d/exabgp.conf
    echo 'd /var/run/exabgp 0755 exabgp exabgp -' > /etc/tmpfiles.d/exabgp.conf

    service exabgp stop
    systemctl enable exabgp
    service exabgp start
    systemctl is-active --quiet exabgp || echo exabgp is running

    echo "NO exabgp config has been appliled"
}

function main()
{
    install_exabgp

	exit 0
}

################################################################################
# Main
################################################################################

main $*

