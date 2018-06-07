:
cd /tmp/
git clone https://github.com/deic-dk/ddps-node.git
cd ddps-node
bash install_ddpsapi.sh
# error at line 45
pm2 startup 2>&1 | tail -1
#pm2 startup 2>&1 | tail -1

pm2 startup 
pm2 save
