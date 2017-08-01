#
# $Header: /opt/UNImsp/src/RCS/common.sh,v 1.2 2012/04/12 09:49:54 root Exp $
#

#
# Functions
#
choice_of()
# purpose     : Lav simpel tekstuel menu, hvis argumentet til $0 matcher mere end en host
# arguments   : None
# return value: None
# see also    :
{
	clear_screen
	echo
	echo "Choose a host ('e' to exit): "
	tput cols | awk '{ while ( $1 -- > 0) printf("-") }'
	select CHOICE
	do
		break
	done
}


function clear_screen {
	echo -en "\\033[2J\\033[1;1H"
}

function logit() {
# purpose     : Timestamp output
# arguments   : Line og stream
# return value: None
# see also    :
	LOGIT_NOW="`date '+%H:%M:%S (%d/%m)'`"
	STRING="$*"

	if [ -n "${STRING}" ]; then
		$echo "${LOGIT_NOW} ${STRING}" >> ${MY_LOGFILE}
		if [ "${VERBOSE}" = "TRUE" ]; then
			$echo "${LOGIT_NOW} ${STRING}"
		fi
	else
		while read LINE
		do
			if [ -n "${LINE}" ]; then
				$echo "${LOGIT_NOW} ${LINE}" >> ${MY_LOGFILE}
				if [ "${VERBOSE}" = "TRUE" ]; then
					$echo "${LOGIT_NOW} ${LINE}"
				fi
			else
				$echo "" >> ${MY_LOGFILE}
			fi
		done
	fi
}

# purpose     : Change case on word
# arguments   : Word
# return value: GENDER=word; GENDER=`toLower $GENDER`; echo $GENDER
# see also    :
toLower() {
echo $1 | tr "[:upper:]" "[:lower:]"
}

toUpper() {
echo $1 | tr  "[:lower:]" "[:upper:]"
}


assert () {
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

function is_valid_ip()
# purpose     : Test an IPv4 address for validity
# arguments   : a.b.c.d
# return value: 0 if ok else bad
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
# see also    :
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

#
# Initialize. Main. Sort-of
#
# eval `resize`		# /usr/X11/bin/resize
#
# Vars
#
PREFIX=/opt/UNImsp/
ETCDIR=${PREFIX}/etc
LIBDIR=${PREFIX}/lib
DBDIR=${PREFIX}/db
DB=${DBDIR}/msp.sl3

# MY_LOGFILE=/dev/null

#
# Default strings for simple menu building
#
DASHES="`tput cols | awk '{ while ( $1 -- > 0) printf(\"-\") }'`"
PS3="$DASHES
Your choice: "

STR0="stop"

echo="builtin echo"
case ${N}$C in
    "") if $echo "\c" | grep c >/dev/null 2>&1; then
        N='-n'
    else
        C='\c'
    fi ;;
esac

# without theese the rest won't work
REQUIRED="gawk gsed gfind sqlite3"
REQUIRED="sqlite3"

for tool in ${REQUIRED}; do
	if ! type $tool >/dev/null 2>&1; then
		echo "ERROR: \"$tool\" required but not found. Check \$PATH or install \"$tool\"."
		exit 2
	fi  
done
