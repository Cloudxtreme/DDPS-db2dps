# ---- Will be extracted and used by remote.sh ----
#:REMOTE-INFO-BEGIN
# TARGETHOST   deployment/test host or IP address, e.g. user@1.2.3.4
TARGETHOST      = rnd@ddps.deic.dk
#TARGETHOST      = sysadm@ddps.ssi.i2.dk
#->TARGETHOST      = sysadm@172.16.201.113
# UPLOADDIR    top directory for the source; everything from '.' will be synced
#              with rsync to there! The directory must exist
UPLOADDIR       = /opt/db2dps/src/

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
PROJDIR         = ../../DDPS-db2dps

#:REMOTE-INFO-END
#
# Makefile for /opt/db2dps/src
#
# NTHA 2016
#
# vim: set nonu ts=4 sw=4 tw=0:
#
PREFIX		= /opt/db2dps
BINDIR		= $(PREFIX)/bin
TMPDIR		= $(PREFIX)/tmp
LOGDIR		= $(PREFIX)/log
ETCDIR		= $(PREFIX)/etc
INITDIR		= $(PREFIX)/etc/init.d

SRCDIR		= $(PREFIX)/src

iniparser 	= iniparser
libini		= $(iniparser)/src

sysinit		= /etc/init.d/db2dps

INSTALL		= $(PREFIX)/src/install-sh
SRCTOMAN	= $(PREFIX)/src/srctoman
#
# required perl modules will be installed by default target (see install_perl_modules)
pkgs		= libnet-openssh-compat-perl liblist-moreutils-perl libnet-openssh-compat-perl libnet-ssh2-perl libproc-daemon-perl libnetaddr-ip-perl libdbi-perl libdbd-pg-perl libtypes-path-tiny-perl libnetaddr-ip-perl libtypes-path-tiny-perl libnet-sftp-foreign-perl

GID			= rnd
UID			= rnd

CC      	?= gcc
AR	    	?= ar
ARFLAGS 	+= rcv
RM      	?= rm -f

CFLAGS  += -g -O0 -I/usr/include/postgresql -I$(libini) -L$(iniparser) -L$(libini) -std=c99 
LDFLAGS  = -lpq -liniparser

RC			= db2dpsrc
CFILES		= db2dps.c concat.c strsplit.c daemonize.c version.c
HFILES		= db2dps.h version.h license.h
PRODINI		= db.ini
TESTINI		= test.ini

prog		= db2dps
target		= $(BINDIR)/db2dps

initrc		= $(INITDIR)/$(RC)
dbini		= $(ETCDIR)/$(PRODINI)

default:	$(prog)

# default:	exabgpsyntax

# perl-version - mimic c version: add version information, set mode and print version. Do not install
$(prog):	hostcheck db2dps.pl version.pm install_perl_modules
			$(RM) $(prog)
			@sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}'  db2dps.pl > db2dps
			@chmod 555 db2dps
			./$(prog) -V
			sudo ./$(prog) -s 2 -v

exabgpsyntax:
			perl ./test-bgp-rules.pl | ssh rnd@exabgp1 'cat > /var/run/exabgp/exabgp.cmd'

install:	hostcheck $(target) $(initrc) $(dbini) $(sysinit)

run:		$(target) $(initrc) $(dbini)
			$(target) -v -s 2

test:		$(prog) $(TESTINI)
			$(SRCDIR)/$(prog) -V
			( sleep 10; touch `sed '/shutdown/!d; s/.*=[\t ]*//' test.ini` ) &
			$(SRCDIR)/$(prog) -v -s 2 -f $(TESTINI)

hostcheck:
	@if [ "`hostname -f`" != "`echo $(TARGETHOST) | sed 's/.*@//'`" ]; then					\
		echo "make should not be executed on the wrong host ... ";							\
		echo "hostname = `hostname` expected `echo $(TARGETHOST) | sed 's/.*@//'`, bye ";	\
		exit 1;																				\
	fi
	chmod 555 $(INSTALL) $(SRCTOMAN)

# Unused article on how to Write Linux Init Scripts Based on LSB Init Standard:
# http://www.thegeekstuff.com/2012/03/lsbinit-script/
$(sysinit): $(RC)
			sudo $(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $(RC) /etc/init.d
			sudo update-rc.d db2dpsrc defaults
			sudo systemctl enable db2dpsrc
			sudo systemctl start db2dpsrc
			sudo systemctl status db2dpsrc

dirs:
			sudo mkdir -p $(PREFIX)/bin $(PREFIX)/tmp $(PREFIX)/log $(PREFIX)/src $(PREFIX)/etc/init.d
			sudo chown -R $(UID):$(GID) $(PREFIX)

$(initrc):	$(RC)
			$(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $(RC) $(INITDIR)

$(target):	$(prog)
			$(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $(prog) $(BINDIR)

$(dbini):	$(PRODINI)
			$(INSTALL) -c -m 0755 -o $(UID) -g $(GID) $(PRODINI) $(ETCDIR)


# Install required perl modules from $(pkgs)
install_perl_modules:
	for P in $(pkgs);							\
	do											\
		dpkg -s "$$P" >/dev/null 2>&1;			\
		case $$? in								\
			0) : 								\
			;;									\
			1) sudo apt-get -y install $$P		\
			;;									\
		esac									\
	done

#
# below are only targets relevant for the c-version
#
leaktest: $(target)
			# valgrind --leak-check=full --show-leak-kinds=all $(target) -v -s 2
			# See http://valgrind.org/docs/manual/faq.html#faq.deflost
			# Also check memory leak med 'memstat -w -p pid'
			( sleep 10; touch `sed '/shutdown/!d; s/.*=[\t ]*//' test.ini` ) &
			valgrind --verbose --leak-check=full --show-leak-kinds=all $(SRCDIR)/$(prog) -v -s 2 -f $(TESTINI) 2>&1 | tee memleak.log
			@echo trace saved as memleak.log

# Not used in production
# DEFS		= DO_DEBUG
# DEFS		= NO_DEBUG
# $(CC) -D$(DEFS) $(CFLAGS) -o $(target) $(CFILES) $(LDFLAGS)

# PostgreSQL C tutorial
#	http://zetcode.com/db/postgresqlc/
#$(prog): $(CFILES) Makefile $(RC) $(HFILES) iniparser/libiniparser.a
#			$(CC) $(CFLAGS) -o $(prog) $(CFILES) $(LDFLAGS)

iniparser/libiniparser.a:
		test -d iniparser || git clone https://github.com/ndevilla/iniparser.git
		cd iniparser && $(MAKE) check example

libssh2:
		wget -N https://libssh2.org/download/libssh2-1.7.0.tar.gz
		tar xvfpz libssh2-1.7.0.tar.gz
		cd libssh2-1.7.0 && ./configure --prefix=/opt/db2dps && make 

SmallSimpleSSH: SmallSimpleSSH.c
		gcc -g -I/usr/include/postgresql -Iiniparser/src -Liniparser -Liniparser/src -std=c99 SmallSimpleSSH.c -o SmallSimpleSSH -lpq -liniparser -lcrypt -lcrypto -lssh2 -lz

01_ssh2_echo: 01_ssh2_echo.c
		gcc -g -I/usr/include/postgresql -Iiniparser/src -Liniparser -Liniparser/src -std=c99 01_ssh2_echo.c -o 01_ssh2_echo -lpq -liniparser -lcrypt -lcrypto -lssh2 -lz

ssh2_echo: ssh2_echo.c
		gcc -g -I/usr/include/postgresql -Iiniparser/src -Liniparser -Liniparser/src -std=c99 ssh2_echo.c -o ssh2_echo -lpq -liniparser -lcrypt -lcrypto -lssh2 -lz

sshcat: sshcat.c
		gcc -g -I/usr/include/postgresql -Iiniparser/src -Liniparser -Liniparser/src -std=c99 sshcat.c -o sshcat -lpq -liniparser -lcrypt -lcrypto -lssh2 -lz

ssh_test: ssh_test.c
		gcc -g -I/usr/include/postgresql -Iiniparser/src -Liniparser -Liniparser/src -std=c99 ssh_test.c -o ssh_test -lpq -liniparser -lcrypt -lcrypto -lssh2 -lz

sftp_append: sftp_append.c
		gcc -g -I/usr/include/postgresql -Iiniparser/src -Liniparser -Liniparser/src -std=c99 sftp_append.c -o sftp_append -lpq -liniparser -lcrypt -lcrypto -lssh2 -lz

ssh2_agent: ssh2_agent.c
		gcc -g -I/usr/include/postgresql -Iiniparser/src -Liniparser -Liniparser/src -std=c99 ssh2_agent.c -o ssh2_agent -lpq -liniparser -lcrypt -lcrypto -lssh2 -lz


# der må være forskel på den installerede system libssh2 og dén kildetekst jeg har hentet ...
scp_nonblock: scp_nonblock.c
		gcc -g -I/usr/include/postgresql -Iiniparser/src -Liniparser -Liniparser/src -std=c99 scp_nonblock.c -o scp_nonblock ../libssh2-1.7.0/src/.libs/libssh2.a -lpq -liniparser -lcrypt -lcrypto -lz

scp: scp.c
		gcc -g -I/usr/include/postgresql -Iiniparser/src -Liniparser -Liniparser/src -std=c99 scp.c -o scp ../libssh2-1.7.0/src/.libs/libssh2.a -lpq -liniparser -lcrypt -lcrypto -lz

scp_write: scp_write.c
		gcc -g -I/usr/include/postgresql -Iiniparser/src -Liniparser -Liniparser/src -std=c99 scp_write.c -o scp_write ../libssh2-1.7.0/src/.libs/libssh2.a -lpq -liniparser -lcrypt -lcrypto -lz

#
# Testing not related to target
#

TEST_APPS	  = lib_version.c list_tables.c multiple_rows.c psql.c query_version.c server_version.c str.c
TEST_OBJS	  = $(TEST_APPS:.c=.o)
TEST_EXEC	  = $(TEST_OBJS:.o=)

print:
		if [ `uname` != "Darwin" ]; then echo requires Darwin with a2ps and pstopdf, sorry; exit 1; fi
		a2ps --no-header --borders=no --highlight-level=heavy --pretty-print=c --tabsize=4 --columns=1 --font-size=7 --landscape --line-numbers=1 db2dps.c -o - | pstopdf -i -o /tmp/print.pdf

#carefull: below be dragons! You cannot use the same $ in _shell_ and in Makefile ...
#@sed '/[\t ]*\*++/,/[\t ]*\*--/!d; s/.*++$$//; s/\*//; s/^[\t ]//; s/.*--$$//; s/^[\t ]#/#/' < db2dps.c
md:
		@sed '/[	 ]*\#++/,/[	 ]*\#--/!d; s/^#//; s/^ #/#/; /^++/d; /^--/d;' < db2dps.pl

% : %.c
		$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

# [Disable implied rules](http://stackoverflow.com/questions/4122831/disable-make-builtin-rules-and-variables-from-inside-the-make-file)
# as ``make db2dps`` will create ``db2dps`` from ``db2dps.sh``
#	cat db2dps.sh >db2dps
#	chmod a+x db2dps

.SUFFIXES:

.SILENT:
