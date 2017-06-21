:

echo "ifconfig -a ;"
echo "ifconfig    192.168.99.10/24"

rsync -avzH cfg db deb dev.lst install.sh add-interface-cfg.sh start.sh sysadm@ddps-dev:/var/tmp/install/
