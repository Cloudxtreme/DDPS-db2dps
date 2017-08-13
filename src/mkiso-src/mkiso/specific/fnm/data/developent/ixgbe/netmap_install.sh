#!/bin/bash

ixgbe_version='4.1.5';
e1000e_version='3.2.7.1';
igb_version='5.3.3.2';
netmap_git_commit='add1e50657e6861db791067804001307ebb5cf86';
selected_driver='ixgbe'
uname_r=`uname -r`;

echo $uname_r
temp_folder=/root/files/data/netmap/install

#apt-get update
#apt-get install -y linux-headers-$uname_r git make gcc

if [ ! -d "$temp_fllder" ]; then
	mkdir -p $temp_folder
fi

cd $temp_folder


#    if ($selected_driver eq 'e1000e') {
#        system("git clone https://github.com/pavel-odintsov/e1000e-linux-netmap.git");
#    }

git clone https://github.com/pavel-odintsov/ixgbe-linux-netmap.git

#    if ($selected_driver eq 'igb') {
#        system("git clone https://github.com/pavel-odintsov/igb-linux-netmap.git");

git clone https://github.com/luigirizzo/netmap.git
cd  "netmap"

# Get specific version
# git checkout $netmap_git_commit		# fails

cd LINUX

# Remove variables which will conflict with variables defined in driver
sed -i '/^char ixgbe_driver_name/d' ixgbe_netmap_linux.h
sed -i '/^#define ixgbe_driver_name netmap_ixgbe_driver_name/d' ixgbe_netmap_linux.h


cat << EOF > ixgbe-override
ixgbe-dst := ixgbe
ixgbe-patch := #(leave empty) 
ixgbe-src := $temp_folder/ixgbe-linux-netmap/ixgbe-$ixgbe_version/src/
EOF

#    if ($selected_driver eq 'e1000e') {
#        open my $e1000e_fl, '>', "e1000e-override" or die "Can't create override file\n";
#        print {$e1000e_fl} <<DOC;
#e1000e-dst := e1000e
#e1000e-patch := #(leave empty) 
#e1000e-src := $temp_folder/e1000e-linux-netmap/e1000e-$e1000e_version/src/
#DOC
#        close($e1000e_fl);
#    }

#    if ($selected_driver eq 'igb') {
#        open my $igb_fl, '>', "igb-override" or die "Can't create override file\n";
#        print {$igb_fl} <<DOC;
#igb-dst := igb
#igb-patch := #(leave empty) 
#igb-src := $temp_folder/igb-linux-netmap/igb-$igb_version/src/
#DOC
#        close($igb_fl);
#    }   

./configure  --override=ixgbe-override --drivers=ixgbe

#    if ($selected_driver eq 'e1000e') {
#        system("./configure  --override=e1000e-override --drivers=e1000e");
#    }
#  
#    if ($selected_driver eq 'igb') {
#        system("./configure  --override=igb-override --drivers=igb");
#    }
# 
    # We should pass  
(
cd $temp_folder/netmap/LINUX
make
case $? in 
	0)	: # ok
	;;
	*)	echo "Could not make project"
		exit 0
esac
)

rmmod ixgbe


#    if ($selected_driver eq 'e1000e') {
#        print "Call: rmmod e1000e\n";
#    }

#    if ($selected_driver eq 'igb') {
#        print "Call: rmmod igb\n";
#    }

rmmod netmap
insmod $temp_folder/netmap/LINUX/netmap.ko

# We need this on recent distros of Ubuntu and Debian
modprobe vxlan

insmod $temp_folder/netmap/LINUX/ixgbe/ixgbe.ko

#    if ($selected_driver eq 'e1000e') {
#        print "Call: insmod $temp_folder/netmap/LINUX/e1000e/e1000e.ko\n";
#    }
#
#    if ($selected_driver eq 'igb') {
#        print "Call: insmod $temp_folder/netmap/LINUX/igb/igb.ko\n";
#    }
#}
#    }
