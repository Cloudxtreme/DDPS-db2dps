# ---- Will be extracted and used by remote.sh ----
#:REMOTE-INFO-BEGIN
# TARGETHOST   deployment/test host or IP address, e.g. user@1.2.3.4
#TARGETHOST      = uninth@ddps.deic.dk
TARGETHOST      = root@ddps-dev
#TARGETHOST      = sysadm@ddps.ssi.i2.dk
#TARGETHOST      = sysadm@172.16.201.113
# UPLOADDIR    top directory for the source; everything from '.' will be synced
#              with rsync to there! The directory must exist
UPLOADDIR       = mkiso-src/

# Path to local and remote rsync
RRSYNC          = /usr/bin/rsync
LRSYNC          = /usr/bin/rsync
# Path to local ssh
SSH             = /usr/bin/ssh
# Arguments to rsync, EXCLUDE_FILE will be appended
EXCLUDE_FILE    = rsync_exclude.txt
RSYNC_ARGS      = -avzH --exclude-from
SSH_ARGS        =  -Tq -o LogLevel=error

# This directory (source)
SRCDIR          = .

# Project directory -- see project_template
PROJDIR         = ../../../DDPS-db2dps

#:REMOTE-INFO-END
#
# Makefile for /opt/db2dps/src/mkiso-src
#
# NTHA 2016
#
# vim: set nonu ts=4 sw=4 tw=0:
#
PREFIX		= /opt/mkiso
PROJECT		= mkiso/

GID			= root
UID			= root

EXCLUDE_INSTALL	= exclude_from_install.txt

pkgs		= mkisofs curl

install:	hostcheck install_pkgs
	#  fix VERSION and make it a bit more elegant
	sudo rsync -avzH --delete-before --exclude-from=$(EXCLUDE_INSTALL) $(PROJECT) $(PREFIX)

uninstall:
			echo remove everything below $(PREFIX)

hostcheck:
	@if [ "`hostname -f`" != "`echo $(TARGETHOST) | sed 's/.*@//'`" ]; then					\
		echo "make should not be executed on the wrong host ... ";							\
		echo "hostname = `hostname` expected `echo $(TARGETHOST) | sed 's/.*@//'`, bye ";	\
		exit 1;																				\
	fi

install_pkgs:
	for P in $(pkgs);						\
	do										\
		dpkg -s "$$P" >/dev/null 2>&1;		\
		case $$? in							\
			0)	:							\
			;;								\
			1)	sudo apt-get -y install $$P	\
			;;								\
		esac								\
	done									\

