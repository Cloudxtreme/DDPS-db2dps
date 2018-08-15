#!/bin/bash
#

apt-get install -y unzip

cd /tmp

test -d /opt/ngx/ddosgui || mkdir -p /opt/ngx/ddosgui
rm -rf /opt/ngx/ddosgui/*
cd /opt/ngx/ddosgui/
wget https://github.com/deic-dk/gossamer/releases/download/v1.0-beta/pro.zip
unzip pro.zip
mv pro/* .
rm -fr pro pro.zip

IF_HOST=`ifconfig | sed '/inet/!d; /inet6/d; /127.0.0.1/d; s/.*addr://; s/ .*$//'`

find ./ -type f -exec sed -i "s/10.33.1.97/${IF_HOST}/g" {} \;

nginx -s reload

