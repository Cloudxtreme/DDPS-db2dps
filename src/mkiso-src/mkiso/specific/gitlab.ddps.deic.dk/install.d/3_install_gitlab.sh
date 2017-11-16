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


function install_gitlab()
{
    # from https://about.gitlab.com/installation/#ubuntu
    echo "$0: installing gitlab dependencies  .... "
    apt-get install -y curl openssh-server ca-certificates

    #debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
    #debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y postfix mailutils
    cat <<-"EOF" > /etc/postfix/main.cf
    myhostname = gitlab.ddps.deic.dk
    myorigin = $mydomain
    relayhost = $mydomain
    inet_interfaces = loopback-only
    mydestination =
EOF

    echo "$0: postfix installed as Postfix on a null client"
    # see http://www.postfix.org/STANDARD_CONFIGURATION_README.html
    # postconf -e "postfix_mydestination = localhost, blah.deblah.com.au"

    echo "$0: installing gitlab .... "
    curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
    # https://about.gitlab.com/installation/#ubuntu
    export EXTERNAL_URL="http://gitlab.ddps.deic.dk"
	apt-get install gitlab-ee

    echo "$0: applying default gitlab configuration ... "
	gitlab-ctl reconfigure
    
    # the following is based on 
    # https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-on-centos-7

    echo "$0: enableing ssl on gitlab build-in nginx ... "
    C=DK
    ST=Sjaelland
    L='Kgs Lyngby'
    O=deic.dk
    OU='Deic Development Lab -- project DDPS'
    CN='gitlab.ddps.deic.dk'

    mkdir /etc/gitlab/ssl
    chmod 700 /etc/gitlab/ssl

    # 25 years -- will be retired by then
    openssl req -x509 -nodes -days 8900 -newkey rsa:2048 -keyout /etc/gitlab/ssl/nginx-selfsigned.key -out /etc/gitlab/ssl/nginx-selfsigned.crt -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN"

    openssl dhparam -out /etc/gitlab/ssl/dhparam.pem 2048

    openssl x509 -in /etc/gitlab/ssl/nginx-selfsigned.crt -text -noout

    # preserve the default configration for later
    test -f /etc/gitlab/gitlab.rb.org || {
        cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.org
    }

    # force httpS
    sed "s%^external_url.*%external_url 'https://gitlab.ddps.deic.dk'%" /etc/gitlab/gitlab.rb.org > /etc/gitlab/gitlab.rb

    cat << EOF >> /etc/gitlab/gitlab.rb
nginx['redirect_http_to_https'] = true
# For GitLab
nginx['ssl_certificate'] = "/etc/gitlab/ssl/nginx-selfsigned.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/nginx-selfsigned.key"
EOF

    # reconfigure gitlab with the new configuration
    gitlab-ctl reconfigure
    echo "$0: gitlab installed -- finish the installation from a browser: URL=http://gitlab.ddps.deic.dk"


	# sshd_config: UsePAM yes required for git to work (git pull git@ ... etc)
	savefile /etc/ssh/sshd_config
	(
		sed 's/^UsePAM.*/UsePAM yes/;'
		< /etc/ssh/sshd_config.org
	) > /etc/ssh/sshd_config
        chmod 0644 /etc/ssh/sshd_config
        chown root:root /etc/ssh/sshd_config
        service ssh restart

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

    install_gitlab

	echo "$0: all done"

	exit 0
}

################################################################################
# Main
################################################################################

main $*

