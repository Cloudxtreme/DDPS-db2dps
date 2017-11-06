#!/bin/sh
#
# $Header$
#
#--------------------------------------------------------------------------------------#
# TODO
#
#--------------------------------------------------------------------------------------#

function main()
{
	# check on how to suppress newline (found in an Oracle installation script ca 1992)
	echo="/bin/echo"
	case ${N}$C in
		"") if $echo "\c" | grep c >/dev/null 2>&1; then
			N='-n'
		else
			C='\c'
		fi ;;
	esac

    echo "$0: installing exabgp and socat .... "
    apt-get -y install exabgp socat
    echo "$0: installing configuration files ... "
    /bin/cp /root/files/data/exabgp/* /etc/exabgp/
    echo 'd /var/run/exabgp 0755 exabgp exabgp -' > /usr/lib/tmpfiles.d/exabgp.conf
    service exabgp stop
    systemctl enable exabgp
    service exabgp start
    systemctl is-active exabgp

	echo "$0: all done"

	exit 0
}

################################################################################
# Main
################################################################################

main $*

