#!/usr/bin/perl

use strict;
use warnings;

# We could use old: 3.23.2.1 too
my $ixgbe_version = '4.1.5';
my $e1000e_version = '3.2.7.1';
my $igb_version = '5.3.3.2';

my $netmap_git_commit = 'add1e50657e6861db791067804001307ebb5cf86';

# ixgbe or e1000e or igb
my $selected_driver = 'e1000e';

install_netmap();

sub install_netmap {
    my $uname_r = `uname -r`;
    chomp $uname_r;

    system("apt-get update");
    system("apt-get install -y linux-headers-$uname_r git make gcc");
   
    my $temp_folder = `mktemp --directory --tmpdir=/tmp netmap_build_tmp_folder.XXXXXXXXXX`;
    chomp $temp_folder;

    unless ($temp_folder && -e $temp_folder) {
        die "Could not create temp folder\n";
    }

    chdir $temp_folder;

    if ($selected_driver eq 'e1000e') {
        system("git clone https://github.com/pavel-odintsov/e1000e-linux-netmap.git");
    }

    if ($selected_driver eq 'ixgbe') {
        system("git clone https://github.com/pavel-odintsov/ixgbe-linux-netmap.git");
    }

    if ($selected_driver eq 'igb') {
        system("git clone https://github.com/pavel-odintsov/igb-linux-netmap.git");
    }

    system("git clone https://github.com/luigirizzo/netmap.git");
    chdir "netmap";

    # Get specific version
    system("git checkout $netmap_git_commit");
    chdir("LINUX");

    if ($selected_driver eq 'ixgbe') {
        # Remove variables which will conflict with variables defined in driver
        system("sed -i '/^char ixgbe_driver_name/d' ixgbe_netmap_linux.h");
        system("sed -i '/^#define ixgbe_driver_name netmap_ixgbe_driver_name/d' ixgbe_netmap_linux.h");
    }

    if ($selected_driver eq 'ixgbe') {
        open my $fl, '>', "ixgbe-override" or die "Can't create override file\n";
        print {$fl} <<DOC;
ixgbe-dst := ixgbe
ixgbe-patch := #(leave empty) 
ixgbe-src := $temp_folder/ixgbe-linux-netmap/ixgbe-$ixgbe_version/src/
DOC
        close($fl);
    }

    if ($selected_driver eq 'e1000e') {
        open my $e1000e_fl, '>', "e1000e-override" or die "Can't create override file\n";
        print {$e1000e_fl} <<DOC;
e1000e-dst := e1000e
e1000e-patch := #(leave empty) 
e1000e-src := $temp_folder/e1000e-linux-netmap/e1000e-$e1000e_version/src/
DOC
        close($e1000e_fl);
    }

    if ($selected_driver eq 'igb') {
        open my $igb_fl, '>', "igb-override" or die "Can't create override file\n";
        print {$igb_fl} <<DOC;
igb-dst := igb
igb-patch := #(leave empty) 
igb-src := $temp_folder/igb-linux-netmap/igb-$igb_version/src/
DOC
        close($igb_fl);
    }   



    if ($selected_driver eq 'ixgbe') {
        system("./configure  --override=ixgbe-override --drivers=ixgbe");
    }

    if ($selected_driver eq 'e1000e') {
        system("./configure  --override=e1000e-override --drivers=e1000e");
    }
  
    if ($selected_driver eq 'igb') {
        system("./configure  --override=igb-override --drivers=igb");
    }
 
    # We should pass  
    system("PWD=$temp_folder/netmap/LINUX make");
   
    unless ($? == 0) {
        die "Could not make project\n";
    }

    if ($selected_driver eq 'ixgbe') { 
        print "Call: rmmod ixgbe\n";
    }


    if ($selected_driver eq 'e1000e') {
        print "Call: rmmod e1000e\n";
    }

    if ($selected_driver eq 'igb') {
        print "Call: rmmod igb\n";
    }

    print "Call: rmmod netmap\n";
    print "Call: insmod $temp_folder/netmap/LINUX/netmap.ko\n";
    # We need this on recent distros of Ubuntu and Debian
    print "Call: modprobe vxlan\n";

    if ($selected_driver eq 'ixgbe') {
        print "Call: insmod $temp_folder/netmap/LINUX/ixgbe/ixgbe.ko\n";
    }
  
    if ($selected_driver eq 'e1000e') {
        print "Call: insmod $temp_folder/netmap/LINUX/e1000e/e1000e.ko\n";
    }

    if ($selected_driver eq 'igb') {
        print "Call: insmod $temp_folder/netmap/LINUX/igb/igb.ko\n";
    }
}