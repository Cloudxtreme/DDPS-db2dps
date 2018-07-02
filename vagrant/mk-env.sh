#! /usr/bin/env

# 

cat << EOF
SU_SEC=Tour of Enceladus and Titan
SU_SEC_3SHA512=`echo 'secret phrase that would be encoded to the next field' | sha512sum  | awk -F'-' '{ print $1 }'`
SU_ISSUER=DEiC
RU_HOST=127.0.0.1
RU_DBC=postgres
RU_DB_VER=9.5
RU_SCHEMA=netflow
RU_USER=flowuser
RU_PWD=password
RU_SERVER_PORT=4242
IF_HOST=172.22.89.2
IF_SCHEMA=graphite
NODE_ENV=production
EOF


exit 0
