#
# envsubst
#
case `uname` in
    Darwin) export ipv4addr="10.0.2.15/24"
        ;;
    Linux) export ipv4addr=`ip -o -4 addr| awk '$4 !~ /127.0.0.1/ { print $4 }'|head -1`
           export interface=`netstat -rn|awk '$1 == "0.0.0.0" { print $NF }'|head -1`
           export local_addr=`ifconfig $interface |sed '/inet/!d; /inet6/d; s/.*addr://; s/ .*//'|head -1`
           export local_net=`netstat -rn|awk '$1 == "0.0.0.0" { print $2 }'|awk -F'.' '{ print $1 "." $2 "." $3 }'`
        ;;
esac

export dbusers="admin dbadmin flowuser postgres repuser"
export dbpass="password"

export dbusr="dbadmin"
export dbpass="password"
export dbname="netflow"
export ipv4addr="$ipv4addr"
export ipv4listenaddress="$ipv4addr"
export pcp_listen_addresses="$ipv4addr"
export backend_hostname0="$ipv4addr"
export backend_hostname1=""                  # not used
export sr_check_password="password"
export sr_check_database="netflow"

export default_uuid_administratorid="3611a271-50ae-4425-86c5-b58b04393242"
export bootstrap_ip="10.0.0.1"


export ournetworks="10.0.0.0/8 172.16.0.0/12"

export customerid="f561067e-10e3-44ed-ab12-9caed904d8d9"
export fastnetmoninstanceid="aac8c5a6-097b-4c0c-bbe6-fe6677ff7eac"
export uuid="ddpsrules-cli-adm"
export administratorid="$default_uuid_administratorid"

# These does not exist but exabgp is only for demo and is forgiving
export neighbor="${local_net}.3"
export local_as=64621
export peer_as=64601
export router_id="${local_net}.33"
