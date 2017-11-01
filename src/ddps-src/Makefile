# ---- Will be extracted and used by remote.sh ----
#:REMOTE-INFO-BEGIN
# TARGETHOST   deployment/test host or IP address, e.g. user@1.2.3.4
# TARGETHOST      = uninth@ddps.deic.dk
#TARGETHOST      = uninth@ww1.ddps.deic.dk
#TARGETHOST      = uninth@ww2.ddps.deic.dk
TARGETHOST      = uninth@ddps-dev
# UPLOADDIR    top directory for the source; everything from '.' will be synced
#              with rsync to there! The directory must exist
UPLOADDIR       = ddps-src/

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
LIBDIR		= $(PREFIX)/lib
DATADIR		= $(PREFIX)/data
INITDIR		= $(PREFIX)/etc/init.d

SRCDIR		= .

DIRS		= $(BINDIR) $(TMPDIR) $(LOGDIR) $(ETCDIR)/init.d $(ETCDIR)/ssh $(LIBDIR) $(DATADIR)

iniparser 	= iniparser
libini		= $(iniparser)/src

#sysinit		= /etc/init.d/db2dps

INSTALL		= ./install-sh
SRCTOMAN	= ./srctoman
#
# required perl modules will be installed by default target (see install_perl_modules)
pkgs		= libnet-openssh-compat-perl liblist-moreutils-perl libnet-openssh-compat-perl libnet-ssh2-perl libproc-daemon-perl libnetaddr-ip-perl libdbi-perl libdbd-pg-perl libtypes-path-tiny-perl libnetaddr-ip-perl libtypes-path-tiny-perl libnet-sftp-foreign-perl

GID			= root
UID			= root

CC      	?= gcc
AR	    	?= ar
ARFLAGS 	+= rcv
RM      	?= rm -f

CFLAGS  += -g -O0 -I/usr/include/postgresql -I$(libini) -L$(iniparser) -L$(libini) -std=c99 
LDFLAGS  = -lpq -liniparser

RC			= db2dpsrc
SERVICEFILE	= db2dps.service
CFILES		= db2dps.c concat.c strsplit.c daemonize.c version.c
HFILES		= db2dps.h version.h license.h
PRODINI		= db.ini
TESTINI		= test.ini

SQLSTR		= sqlstr.pm

prog		= db2dps
target		= $(BINDIR)/db2dps

initrc		= $(INITDIR)/$(RC)
dbini		= $(ETCDIR)/$(PRODINI)
sqlstr		= $(LIBDIR)/$(SQLSTR)

default:	$(prog)
			./$(prog) -V
			#sudo ./$(prog) -v -s 4

# ssh-keygen  -t ED25519 -b 16384 -f /opt/db2dps/etc/ssh/id_ed25519 -N ""

$(prog):	hostcheck db2dps.pl version.pm install_perl_modules $(sqlstr)
			$(RM) $(prog)
			@sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}'  db2dps.pl > db2dps
			@chmod 555 db2dps

perlfiles	= kill_switch_restart_all_exabgp.pl ddpsrules.pl examon.pl
shellfiles	= default-rules.sh apply-default-rules.sh

# target assumes everything is perl
bin: $(perlfiles)
	for exec in $(perlfiles);																		\
	do																								\
		exec=`basename $$exec .pl`	;							\
		sudo $(RM) $$exec;																			\
		sudo sed -e '/#INCLUDE_VERSION_PM/ {' -e 'r version.pm' -e 'd' -e'}'  $$exec.pl > $$exec;	\
		sudo $(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $$exec $(BINDIR);							\
	done
	for exec in $(shellfiles);																		\
	do																								\
		exec=`basename $$exec .sh`	;							\
		sudo $(RM) $$exec;																			\
		sudo sed -e '/#INCLUDE_VERSION_SH/ {' -e 'r version.SH' -e 'd' -e'}'  $$exec.sh > $$exec;	\
		sudo $(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $$exec $(BINDIR);							\
	done

exabgpsyntax:
			perl ./test-bgp-rules.pl | ssh rnd@exabgp1 'cat > /var/run/exabgp/exabgp.cmd'

update:
			sudo systemctl stop $(SERVICEFILE)
			$(MAKE) install
			
install:	hostcheck dirs $(target) $(initrc) $(dbini) bin $(sqlstr)
			sudo cp $(SERVICEFILE) /etc/systemd/system/
			sudo systemctl enable $(SERVICEFILE)
			sudo systemctl start $(SERVICEFILE)

uninstall:
			# stop the service, disable start 
			sudo systemctl stop $(SERVICEFILE)
			sudo systemctl disable $(SERVICEFILE)
			sudo rm -f /etc/systemd/system/multi-user.target.wants/$(SERVICEFILE) /etc/systemd/system/$(SERVICEFILE)
			sudo systemctl daemon-reload
			sudo systemctl reset-failed
			echo now remove everything below $(PREFIX) and the database netflow from postgres

run:		$(target) $(initrc) $(dbini)
			$(target) -v -s 2

test:		$(prog) $(TESTINI)
			$(SRCDIR)/$(prog) -V
			( sleep 10; touch `sed '/shutdown/!d; s/.*=[\t ]*//' test.ini` ) &
			sudo $(SRCDIR)/$(prog) -v -s 2
			#$(SRCDIR)/$(prog) -v -s 2 -f $(TESTINI)

hostcheck:
	@if [ "`hostname -f`" != "`echo $(TARGETHOST) | sed 's/.*@//'`" ]; then					\
		echo "make should not be executed on the wrong host ... ";							\
		echo "hostname = `hostname` expected `echo $(TARGETHOST) | sed 's/.*@//'`, bye ";	\
		exit 1;																				\
	fi
	chmod 555 $(INSTALL) $(SRCTOMAN)
	$(MAKE) dirs

dirs:
			for D in $(DIRS); 								\
				do											\
				if [ ! -d $$D ]; then						\
						sudo mkdir -p $$D;					\
				fi											\
			done
			#sudo chown -R $(UID):$(GID) $(PREFIX);		\

$(initrc):	$(RC)
			sudo $(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $(RC) $(INITDIR)

$(target):	$(prog)
			sudo $(INSTALL) -c -m 0555 -o $(UID) -g $(GID) $(prog) $(BINDIR)

$(dbini):	$(PRODINI)
			if [ -e ${dbini} ]; then													\
				echo "existing ${dbini} preserved";										\
				echo "not removing existing ${dbini}";									\
				echo "new db.ini installed as ${dbini}.new";							\
				sudo /bin/cp ${PRODINI}	${dbini}.new;									\
			else																		\
				sudo $(INSTALL) -c -m 0755 -o $(UID) -g $(GID) $(PRODINI) $(ETCDIR);	\
			fi

$(sqlstr):	$(SQLSTR)
			sudo $(INSTALL) -c -m 0755 -o $(UID) -g $(GID) $(SQLSTR) $(LIBDIR)

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
		# pstopdf uses $TMPDIR which is also set in Makefie
		if [ `uname` != "Darwin" ]; then echo requires Darwin with a2ps and pstopdf, sorry; exit 1; fi
		a2ps --no-header --borders=no --highlight-level=heavy --pretty-print=c --tabsize=4 --columns=1 --font-size=7 --landscape --line-numbers=1 $(prog).pl -o /tmp/$(prog).ps
		TMPDIR=/tmp pstopdf /tmp/$(prog).ps -o /tmp/$(prog).pdf

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
