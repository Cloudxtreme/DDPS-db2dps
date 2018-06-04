#!/bin/bash

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

	echo "$0: installing package db2dps ... "

    cd /DDPS-db2dps/src/ddps-src/ || {
        echo cd /DDPS-db2dps/src/ddps-src/ failed
        exit 1
    }
    if [ -e *.deb ]; then
        echo installing *deb ...
    else
        echo making from source ...
        make clean; make
    fi
    echo reading and installing dependencies
    apt-get install -y `dpkg -I *deb|sed '/Depends:/!d; s/Depends://; s/,//g'` > /dev/null && echo "done successfully"
    dpkg -i db2dps_*.deb && echo "done successfully"

	echo "$0: all done"

	exit 0
}

################################################################################
# Main
################################################################################

main $*

exit 0

__DATA__

	cat << 'EOF' | su - sysadm

echo in `pwd` as `whoami`

test -d DDPS-db2dps && rm -fr DDPS-db2dps
git clone https://github.com/deic-dk/DDPS-db2dps.git

cd DDPS-db2dps/src/
DIR=`pwd`
for s in *
do
	cd ${DIR}/$s
	chmod 555 install-sh
	make gitinstall
done
EOF


