#!/bin/bash
#
# Se https://nakkaya.com/2012/08/30/create-manage-virtualBox-vms-from-the-command-line/
# and https://www.perkin.org.uk/posts/create-virtualbox-vm-from-the-command-line.html
#
# and https://github.com/netson/ubuntu-unattended
# and https://askubuntu.com/questions/806820/how-do-i-create-a-completely-unattended-install-of-ubuntu-desktop-16-04-1-lts

echo=/bin/echo
case ${N}$C in
	"") if $echo "\c" | grep c >/dev/null 2>&1; then
		N='-n'
	else
		C='\c'
	fi ;;
esac

case $1 in
	*)	GUEST=$1
	;;
	"")	:
	;;
esac


ISODIR="${HOME}/VirtualBox VMs/iso/"
ISO="${ISODIR}/ubuntu-16.04.3-server-amd64-auto-install.${GUEST}.iso"

VM="ubuntu-16.04-${GUEST}-test"

if [ ! -f "${ISO}" ]; then
	echo "iso ${ISO} not found" 
	exit 
fi

FOUND=`VBoxManage list vms | awk '$1 ~ /'$VM'/ { gsub(/\"/, ""); print $1 }'`
if [ "${FOUND}" = "${VM}" ]; then
	echo "VM ${VM} exists, remove with "
	echo "VBoxManage unregistervm ${VM} --delete"
	exit 0
fi

echo "creating guest OS ${VM}"
echo "using iso ${ISO}"

VBoxManage createvm --name ${VM} --register
VBoxManage modifyvm ${VM} --memory 512 --acpi on --boot1 dvd
VBoxManage modifyvm ${VM} --vram 128
 
VBoxManage modifyvm ${VM} --nic1 NAT --bridgeadapter1 en0
VBoxManage modifyvm ${VM} --nic2 hostonly --hostonlyadapter2 vboxnet0
 
# AMD PCNet PCI II = Am79C970A
# AMD PCNet FAST III = Am79C973 (the default)
# Intel PRO/1000 MT Desktop = 82540EM
# Intel PRO/1000 T Server = 82543GC
# Intel PRO/1000 MT Server = 82545EM
# Paravirtualized network adapter = virtio-net
 
VBoxManage modifyvm ${VM} --nictype1 82545EM
VBoxManage modifyvm ${VM} --nictype2 82545EM
 
VBoxManage modifyvm ${VM} --cableconnected1 on
VBoxManage modifyvm ${VM} --cableconnected2 on
 
VBoxManage modifyvm ${VM} --macaddress1 "0800276398d2"
VBoxManage modifyvm ${VM} --ostype Ubuntu_64
 
VBoxManage createhd --filename "$HOME/VirtualBox VMs/${VM}/${VM}.vdi" --size 10000
VBoxManage storagectl ${VM} --name "IDE Controller" --add ide
 
VBoxManage storageattach ${VM} --storagectl "IDE Controller"  \
    --port 0 --device 0 --type hdd --medium "$HOME/VirtualBox VMs/${VM}/${VM}.vdi"
 
VBoxManage storageattach "${VM}" --storagectl "IDE Controller" \
	--port 1 --device 0 --type dvddrive --medium "${ISO}"

VBoxManage modifyvm ${VM} --description "scratch host made `date` booted from ${ISO}"
 
VBoxHeadless -s ${VM}	 &
