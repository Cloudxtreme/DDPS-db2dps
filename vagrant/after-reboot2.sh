#! /usr/bin/env bash

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
