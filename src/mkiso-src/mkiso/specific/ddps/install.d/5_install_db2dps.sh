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

    echo "$0: installing db2dps from git ... "
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

	echo "$0: all done"

	exit 0
}

################################################################################
# Main
################################################################################

main $*
