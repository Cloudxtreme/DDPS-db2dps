#!/bin/bash
#
# $Header$
#

VERBOSE=FALSE
DATADIR=/root/files/data/

# functions
function savefile()
{
	if [ ! -f "$1" ]; then
		echo "program error in function savefile, file '$1' not found"
		exit 0
	fi
	if [ ! -f "$1".org ]; then
		echo "$0: saving original $1 as $1.org ... "
		cp "$1" "$1".org
	fi
}

# purpose     : Change case on word
# arguments   : Word
# return value: GENDER=word; GENDER=`toLower $GENDER`; echo $GENDER
# see also    :
function toLower() {
	echo $1 | tr "[:upper:]" "[:lower:]"
}

function toUpper() {
	echo $1 | tr  "[:lower:]" "[:upper:]"
}


function install_go()
{
    echo "$0: installing golang go1.9.2 .... "
    DIR=/usr/local/src/go1.9.2
    test -d ${DIR} || mkdir -p ${DIR}
    cd ${DIR}
    wget -N https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz
    tar -xf go1.9.2.linux-amd64.tar.gz
    test -d /usr/local/go && /bin/rm -fr /usr/local/go
    echo moving go to /usr/local ... 
    mv go /usr/local
    echo  adding go to \$PATH ...
    cat <<-EOF >/etc/profile.d/go.sh
    PATH=$PATH:/usr/local/go/bin/
EOF


}

function assert () {
# purpose     : If condition false then exit from script with appropriate error message.
# arguments   : 
# return value: 
# see also    : e.g.: condition="$a -lt $b"; assert "$condition" "explaination"

    E_PARAM_ERR=98 
    E_ASSERT_FAILED=99 
    if [ -z "$2" ]; then        #  Not enough parameters passed to assert() function. 
        return $E_PARAM_ERR     #  No damage done. 
    fi  
    if [ ! "$1" ]; then 
   	# Give name of file and line number. 
        echo "Assertion failed:  \"$1\" File \"${BASH_SOURCE[1]}\", line ${BASH_LINENO[0]}"
		echo "	$2"
        exit $E_ASSERT_FAILED 
    # else 
    #   return 
    #   and continue executing the script. 
    fi  
}

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

	#
	# Process arguments
	#
	while getopts v opt
	do
	case $opt in
		v)	VERBOSE=TRUE
		;;
		*)	echo "usage: $0 [-v]"
			exit
		;;
	esac
	done
	shift `expr $OPTIND - 1`

	MY_DIR=`dirname $0`

	echo "$0: running from '$MY_DIR' ... "
	cd ${MY_DIR} || {
		echo "chdir ${MY_DIR} failed"; exit 0
	}

    install_go

	echo "$0: all done"

	exit 0
}

################################################################################
# Main
################################################################################

main $*

