#!/bin/sh

# Set permissions on /home/sysadm/.ssh/
chown -R sysadm:sysadm /home/sysadm
chmod 700              /home/sysadm/.ssh /home/sysadm/.ssh/*
chmod 755 /tmp/setperm.sh
