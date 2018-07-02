#!/bin/bash
#install ngnx
cd /tmp
apt-get update
apt-get -y install nginx
# setup configuration file
cat>/etc/nginx/sites-available/client.conf<<EOF
server {
    listen 8080;
    server_name localhost;
    root        /opt/ngx/ddosgui;
    index       index.html index.htm;

    # log files
    access_log  /var/log/nginx/nginx.access.log;
    error_log   /var/log/nginx/nginx.error.log;

    ## default location ##
    location / {
        include /etc/nginx/mime.types;
        try_files $uri $uri/ /index.html?/$request_uri;
    }
}
EOF
# create symbolic link to configuration file
ln -sf /etc/nginx/sites-available/client.conf /etc/nginx/sites-enabled/client.conf
echo 'Successfully installed and reconfigured nginx'
#run ngnix
nginx -s reload
echo 'nginx running...'