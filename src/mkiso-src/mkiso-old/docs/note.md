

	Det her burde bo i f.eks. /opt/mkiso {bin,etc/ssh,downloads} med
	
		bin/ubuntu-server-auto-install	<ubuntu version> [ <specific/host> ]

		common/authorized_keys
		common/cmod_1.1-2.deb
		common/dailybuandupdate_1.6-1.deb
		common/install.sh
		common/grouproot_1.2-1.deb
	
		specific/fnm-gemeric/ ...
		specific/fnm-ipaddr1/ ...
		specific/fnm-ipaddr2/ ...
		specific/fnm-ipaddr3/ ...
		specific/ddps/
		
		...
	
	Og bruges til at lave specifikke ISO'er pr. host.
	
	En speficik host kunne være en fnm hvor OpenVPN keys hentes med en wget.


