#!/bin/bash
#
# Work in progress -- doesn't work yet
#

exit 0

DDOSCLIENT='/opt/ngx/ddosgui'
# npm install bower and ember-cli for ember build
npm install -g bower
# same version as in package.json of gossamer
npm install -g ember-cli@2.13.0

# git clone ember
cd /tmp
git clone https://github.com/deic-dk/gossamer.git gossamer
cd gossamer
# create .env file
## create .env.deploy.production
cat << EOF > .env.deploy.production
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
cp .env.deploy.production .env

bower install --allow-root
npm install
npm test
echo 'Successfully installed DDPS GUI'

## build to ngx/ddosgui
test -d ${DDOSCLIENT} || mkdir -p ${DDOSCLIENT}
chown -R hansolo:staff ${DDOSCLIENT}
# cd gossamer
ember build -prod --output-path ${DDOSCLIENT}

exit 0

