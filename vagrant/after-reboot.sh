#! /usr/bin/env bash
# 
# Se http://pm2.keymetrics.io/docs/usage/startup/#saving-current-processes
#

export HOME=/root/
pm2 resurrect

exit 0

# Måske 
# user may be hamsolo, so something like this may be required:
# hansolo has HOME=/dev/null this must change I think

# stop and delete all previous pm2 processes for hansolo user
  sudo su - hansolo -c "pm2 stop all || true";
  sudo su - hansolo -c "pm2 delete all || true";

# remove startup script and kill any lingering pm2 processes
  sudo pm2 unstartup || true;
  pkill -f pm2 || true;

# start pm2 processes for the 'hansolo' user
  sudo su - hansolo -c "pm2 start /home/hansolo/ecosystem.config.js";

  # save process list and create startup script
  sudo su - hansolo -c "pm2 save;";
  sudo pm2 startup -u hansolo --hp /home/hansolo;

# Eller  fra https://github.com/Unitech/pm2/issues/1055

cat << EOF > /etc/init.d/pm2-init.sh

#snip
NAME=pm2
PM2=/usr/bin/pm2
USER=root

export PATH=$PATH:/usr/bin
export PM2_HOME="/home/ubuntu/.pm2"

super() {
    su - $USER -c "PATH=$PATH; $*"
}

start() {
    echo "Starting $NAME"
    super $PM2 resurrect
}

#snip

EOF
