#!/bin/sh
#
# variables to use
USERNAME=hansolo
PM2DEPL='/opt/deploy-ddosapi'
DDOSAPI='/opt/ddosapi'
ME=`basename $0`

# create user hansolo without a home dir
getent passwd ${USERNAME} > /dev/null 2>&1  >/dev/null || adduser --home /dev/null --no-create-home --shell /sbin/nologin --gecos "DDPS node admin" --ingroup staff --disabled-password ${USERNAME}

# create dir to store deploy scripts "ecosystem.json"
test -d ${PM2DEPL} || mkdir -p ${PM2DEPL}
chown -R hansolo:staff ${PM2DEPL}

# create directory ${DDOSAPI} and copy files etc.
# this is where api will install and run into prod, dev or staging folders
test -d ${DDOSAPI} || mkdir -p ${DDOSAPI}
chown -R hansolo:staff ${DDOSAPI}

# install pre-requisite node.js using a PPA
curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh

# verify download
md5sum -c nodesource_setup.sh.md5 >/dev/null 2>&1 || {
    echo "md5sum for nodesource_setup.sh changed, please review nodesource_setup.sh"
    echo "update check sum with"
    echo "md5sum nodesource_setup.sh  > nodesource_setup.sh.md5"
}

# see https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-ubuntu-16-04
bash nodesource_setup.sh
apt-get -y install nodejs build-essential

# bare bone git server installation required for pm2 / ecosystem.json
# See https://git-scm.com/book/en/v2/Git-on-the-Server-Getting-Git-on-a-Server

sudo apt-get -y install git-core whois upstart
sudo useradd git 
usermod -p '*' git

# create rsa key for root and add to authorized_keys for user git
export HOME=/root
ssh-keygen -q -t rsa  -N '' -f ~root/.ssh/id_rsa
mkdir -p ~git/.ssh && cat ~root/.ssh/id_rsa.pub >  ~git/.ssh/authorized_keys
chown -R git:git ~git

# test ssh access avoiding initial 'host key verification failed'
if [  ! -d /root/.ssh/ ]; then
    mkdir /root/.ssh
fi
ssh-keyscan -H 127.0.0.1 >> /root/.ssh/known_hosts
chmod 700 /root/.ssh/known_hosts

# ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no git@localhost whoami
ssh -o StrictHostKeyChecking=no git@localhost whoami
case $? in
	0)	echo "$0: user git added ok"
	;;
	*)	echo "$0: script error line 39-40 adduser git failed"
		exit 1
	;;
esac

# then change shell
which git-shell>>/etc/shells
chsh git -s $(which git-shell)

mkdir -p /srv/git/project.git 
cd /srv/git/project.git
git init --bare
touch git-daemon-export-ok
chown -R git:git /srv/git

# now for the daemon ...
cat << EOF > /etc/event.d/local-git-daemon
start on startup
stop on shutdown
exec /usr/bin/git daemon \
    --user=git --group=git \
    --reuseaddr \
    --base-path=/opt/git/ \
    /opt/git/
respawn
EOF

initctl start local-git-daemon

echo "$0: bare bone server installed"

# install ddos-api

cd /tmp/
git clone https://gist.github.com/351dc8fe12470e9631f929ace42d858a.git ddosapi-install
ls -al ddosapi-install
sudo bash ddosapi-install/ww-ss.sh
echo 'Successfully installed ddosapi'

# now add the 'project':

mkdir /opt/deploy-ddosapi; cd /opt/deploy-ddosapi

cat << 'EOF' > ecosystem.json.tmpl
{
  "apps": [
    {
      "name": "ddosapi",
      "script": "bin/server.js",
      "instances" : "max",
      "exec_mode" : "cluster",
      "env": {
        "COMMON_VARIABLE": "true"
      },
      "env_production": {
        "NODE_ENV": "production"
      }
    }
  ],

  /**
   * Deployment section
   * http://pm2.keymetrics.io/docs/usage/deployment/
   */
  "deploy": {
    "production": {
      "user": "hansolo",
      "host": "localhost",
      "ref": "origin/master",
      "repo": "ssh://git@localhost/srv/git/project.git",
      "path": "/opt/ddosapi/pro-ddosapi",
      "post-setup": "npm install; ls -la; pwd",
      "pre-deploy": "pm2 startOrRestart /opt/deploy-ddosapi/ecosystem.json --env production",
      "env": {
        "SU_SEC": "${SU_SEC}",
        "SU_SEC_3SHA512": "${SU_SEC_3SHA512}",
        "SU_ISSUER": "${SU_ISSUER}",
        "RU_HOST": "${RU_HOST}",
        "RU_SERVER_PORT": "${RU_SERVER_PORT}",
        "RU_NAMESPACE": "ddosapi",
        "RU_DBC": "postgres",
        "RU_DB_VER": "9.5",
        "RU_SCHEMA": "netflow",
        "RU_USER": "flowuser",
        "RU_PWD": "password",
        "IF_HOST":"192.168.67.3",
        "IF_HOST_PORT":"8086",
        "IF_SCHEMA": "graphite",
        "NODE_ENV": "production"
      }
    },
    "development": {
      "user": "hansolo",
      "host": "localhost",
      "ref": "origin/master",
      "repo": "ssh://git@localhost/srv/git/project.git",
      "path": "/opt/ddosapi/dev-ddosapi",
      "post-setup": "npm install; ls -la; pwd",
      "pre-deploy": "pm2 startOrRestart /opt/deploy-ddosapi/ecosystem.json --env development",
      "env": {
        "SU_SEC": "Tour of Enceladus and Titan",
        "SU_SEC_3SHA512": "01afbf1d6bdea756d91f524feb21aa59a81794b7d15715e95685c370777650340b62972ae39bb993d9b3cdca9e7a2858103a1b70d4b43772c3ffc409ec6817b0",
        "SU_ISSUER": "Ashokaditya",
        "RU_HOST": "localhost",
        "RU_SERVER_PORT": "9696",
        "RU_NAMESPACE": "ddosapi",
        "RU_DBC": "postgres",
        "RU_DB_VER": "9.5",
        "RU_SCHEMA": "netflow",
        "RU_USER": "flowuser",
        "RU_PWD": "password",
        "IF_HOST": "fastnetmon03.vpn.ddps.deic.dk",
        "IF_HOST_PORT":"8086",
        "IF_SCHEMA": "graphite",
        "NODE_ENV": "development"
      }
    }
  }
}
EOF

(
    export SU_SEC="Tour of Enceladus and Titan"
    export SU_SEC_3SHA512="`echo 'secret phrase that would be encoded to the next field' | sha512sum  | awk -F'-' '{ print $1 }'`"
    export SU_ISSUER="DEiC"
    export RU_HOST="127.0.0.1"
    export RU_DBC="postgres"
    export RU_DB_VER="9.5"
    export RU_SCHEMA="netflow"
    export RU_USER="flowuser"
    export RU_PWD="password"
    export RU_SERVER_PORT="4242"
    export IF_HOST="172.22.89.2"
    export IF_SCHEMA="graphite"
    export NODE_ENV="production"

    # TODO: once this works fill out the rest in the template ...
    envsubst < ecosystem.json.tmpl > ./ecosystem.json
)

rm -fr .git/
git init
git add .
git remote add origin git@localhost:/srv/git/project.git
git commit -m 'initial commit'
git push origin master
# git commit --amend --reset-author -m 'minor changes ... '
# git push origin master
git pull origin master

npm install pm2@latest -g
pm2 deploy ecosystem.json production setup
pm2 deploy ecosystem.json production
pm2 save

# The API does not survive reboot, so attemtp to (also) fix that:

cat << 'EOF' > /etc/init.d/pm2-init
#!/bin/sh

### BEGIN INIT INFO
# Provides:          scriptname
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO

NAME=pm2
PM2=/usr/bin/pm2
export HOME="/root"

case $1 in
	*)	pm2 resurrect
		pm2 status
	;;
esac
EOF
chmod 755 /etc/init.d/pm2-init

update-rc.d pm2-init defaults

exit 0
