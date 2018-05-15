#!/bin/sh

USER=sysadm

KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICh0o+Zu/Tv2zgWib3F0YsaBz03NnzQRC17oZ5syENot uninth@macnth.local"

mkdir -p /root/.ssh/ /home/${USER}/.ssh

echo "${KEY}" > /root/.ssh/authorized_keys 
echo "${KEY}"  > /home/${USER}/.ssh/authorized_keys 

chown -R ${USER}:${USER} /home/${USER}
chmod 700              /home/${USER}/.ssh /home/${USER}/.ssh/* /root/ /root/.ssh /root/.ssh/*

