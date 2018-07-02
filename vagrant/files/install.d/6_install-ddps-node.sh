#!/bin/bash
cd /tmp/
# git clone https://github.com/deic-dk/ddosapi.git
# do next two lines
git clone https://gist.github.com/351dc8fe12470e9631f929ace42d858a.git ddosapi-install
# mv 351dc8fe12470e9631f929ace42d858a ddosapi-install
sh /vagrant/mk-env.sh > ddosapi-install/.env
sudo bash ddosapi-install/ww-ss.sh
echo 'Successfully installed ddosapi'

# # Steps to do manually after install
cd /opt/deploy-ddosapi
pm2 deploy ecosystem.json production
pm2 startup 2>/dev/null | tail -1 | sed 's/^\$//'|sh
pm2 save
pm2 ls

# ## run service after postgre runs
#   pm2 deploy ecosystem.json production
## generate startup script
## save processes to resurrect
#   pm2 startup 2>/dev/null | tail -1 | sed 's/^\$//'|sh
#   pm2 save
## list running m2 services
#   pm2 ls
## done
