#!/bin/sh
#
# $Header$
# re-write in perl
#

#
# Vars
#
MYDIR=/path/to/some/dir
MYNAME=`basename $0`
MY_LOGFILE=/var/log/somelogfile
VERBOSE=FALSE
TMPFILE=/tmp/${MYNAME}.tmp

#
# Functions
#
function logit() {
# purpose     : Timestamp output
# arguments   : Line og stream
# return value: None
# see also    :
	LOGIT_NOW="`date '+%H:%M:%S (%d/%m)'`"
	STRING="$*"

	if [ -n "${STRING}" ]; then
		$echo "${LOGIT_NOW} ${STRING}" >> ${MY_LOGFILE}
		if [ "${VERBOSE}" = "TRUE" ]; then
			$echo "${LOGIT_NOW} ${STRING}"
		fi
	else
		while read LINE
		do
			if [ -n "${LINE}" ]; then
				$echo "${LOGIT_NOW} ${LINE}" >> ${MY_LOGFILE}
				if [ "${VERBOSE}" = "TRUE" ]; then
					$echo "${LOGIT_NOW} ${LINE}"
				fi
			else
				$echo "" >> ${MY_LOGFILE}
			fi
		done
	fi
}

function usage() {
# purpose     : Script usage
# arguments   : none
# return value: none
# see also    :
echo $*
cat << EOF

	Usage: `basename $0` options ...
	
	add new host, read options from database or write default vars to local filesystem:
		<-d|-l> -a hostname.tld

	update database with host information from filesystem
		-d  -u hostname.tld

	update local filesystem with info from database
		-l  -u hostname.tld

	See man pages for more info.
EOF
	exit 2
}

clean_f () {
# purpose     : Clean-up on trapping (signal)
# arguments   : None
# return value: None
# see also    :
	$echo trapped
	/bin/rm -f $TMPFILE $MAILFILE
}

function add_ssh_keys()
{
	chattr -i /home/sftpgroup/newrules/.ssh/authorized_keys /home/sftpgroup/newrules/.ssh/
	chattr +i /home/sftpgroup/newrules/.ssh   /home/sftpgroup/newrules/.ssh/*
}

function main()
{
	echo=/bin/echo
	case ${N}$C in
		"") if $echo "\c" | grep c >/dev/null 2>&1; then
			N='-n'
		else
			C='\c'
		fi ;;
	esac

	#
	# Process arguments
	#
	while getopts a:dlu: opt
	do
	case $opt in
		a)	NEWHOST=$OPTARG
		;;
		d)	READ_FROM_DB=1
		;;
		l)	READ_FROM_FILES=1
		;;
		u)	UPDATEHOST=$OPTARG
		;;
		*)	usage
			exit
		;;
	esac
	done
	shift `expr $OPTIND - 1`

#	test -n "$NEWHOST"		|| usage "Error: no new host !"
#	test -n "$UPDATEHOST"	|| usage "Error: no host to update !"

	echo done

	exit 0
}

#
# clean up on trap(s)
#
trap clean_f 1 2 3 13 15

################################################################################
# Main
################################################################################

main $*

exit 0

#
# Documentation and  standard disclaimar
#
# Copyright (C) 2001 Niels Thomas Haugård
# UNI-C
# http://www.uni-c.dk/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the 
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#++
# NAME
#	UNIfwbu.sh 1
# SUMMARY
#	rsync baseret firewall(1) backup
# PACKAGE
#	UNIbackup
# SYNOPSIS
#	UNIfwbu.sh [-v] \fIkonfigurationsfil\fR
# BESKRIVELSE
#	\fCUNIfwbu.sh(1)\fR anvendes til at hente system status,
#	firewall og operativsystems konfigurationsfiler tilbage til
#	sikkerhedsafdelingen, til brug ved en katastrofe reetablering.
#
#	Systemet forudsætter, at pakken \fBUNItools\fR er installeret
#	på firewall'en.
#
#	\fCUNIfwbu.sh(1)\fR udføres periodisk via \fCcron(1)\fR, og
#	startes af \fCUNIrun_fwbu.sh(1)\fR.
#
#	\fCUNIfwbu.sh(1)\fR bruger \fCrsync(1)\fR over \fCssh(1)\fR
#	til at lave dels
# .IP o
#	et dokument med den øjeblikkelige \fIsystem status\fR,
# .IP o
#	en sikkerhedskopi af de øjeblikkelige konfigurationsfiler
#	for firewall og operativsystem,
# .IP o
#	en lokal sikkerhedskopi af den daglige backup af
#	firewall'ens konfigurationsfiler.
#
#	Det er planlagt senere automatisk at flytte dokumenterne ind i
#	et CVS træ, samt at lave versionskontrol og automatisk 
#	opdatering af kundens dokumentation på baggrund af opdagede
#	ændringer.
#
#	Der anvendes et operativsystem specifikt script til at
#	lave system status. Disse scripts ligger i \fC/var/opt/UNIfwbu/etc\fR,
#	og kopieres ud på firewall'en, udføres og slettes. De
#	efterlader fire dokumenter i hjemmekataloget for den bruger
#	der anvendes ved login, og dokumenterne flyttes efterfølgende til
#	log kataloget og de gemmes i én generation:
# .RS
# .TP
#	\fC$HOME/current_system_status\fR
#	System status information (output fra bl.a. \fCnetstat\fR, \fCifconfig\fR,
#	\fCfw stat\fR, osv.)
# .TP
#	\fC$HOME/current_statistical_information\fR
#	Volatil system statistisk information.
#	\fCfw stat\fR, osv.)
# .TP
#	\fC$HOME/.all_files\fR
#	Alle dokumenter der skal tages backup af. Links er resolverede, og 
#	\fC$FWDIR\fR er fundet (ændres med hver opgradering/patching).
#	Dokumentet skal senere danne udgangspunkt for \fCCVS\fR \fCadd\fR og
#	\fCremove\fR kommandoer.
# .TP
#	\fC$HOME/.backup_files\fR
#	Alle dokumenter på et format hensigtsmæssig som argument til \fRrsync(1)\fR.
#	Dette format gør, at filnavne med mellemrum ikke er tilladte.
#
# .RE
#	
# OPTIONS
# .TP
#	\fC-v\fR
#	Verbose; skriv til stdout samt til logfil.
# .TP
#	\fIkonfigurationsfil\fR
#	En kunde kan have mange maskiner der skal tages backup af.
#	Firewall(s), reservemaskiner, snortlogs osv. og der er derfor
#	nødvendigt at kunne håndtere en én kunde til mange maskiner
#	relation.
#	
#	Konfigurationsfil og dokunenter til en specifik kundes
#	maskine(r) ligger under \fC/lan/ssi/\fIkundenavn\fC/hosts\fR.
#	Her er for hver maskine et katalog (maskinens navn) samt
#	et konfigurationsdokument, der skal hedde det samme med
#	extension \fC.conf\fR, f.eks. \fCdefgw.conf\fR.
#
# KONFIGURATIONSFIL
#	Syntaksen er \fIvariabel\fC = \fIværdi\fR. Dokumentet
#	processeres af \fCawk(1)\fR og resultatet sources af
#	\fCbash(1)\fR - så pas på med syntaksen!
#
#	Dokumentet skal indeholde følgende:
# .nf
#	\fC
    1	# Kundens domænenavn -- katalog i /lan/ssi
    2	DOMAIN_NAME = ssi.uni-c.dk
    3	
    4	# navn på maskinen -- det bliver også et katalognavn
    5	HOST_NAME   = defgw
    6	
    7	# maskinens IP -- hertil laves ssh forbindelsen
    8	IP      = 172.16.0.1
    9	
   10	# Hvilken port ssh er bundet til
   11	SSH_PORT    = 22
   12	
   13	# Login på maskinen (som root) med denne bruger
   14	LOGIN_USER  = admin
   15	
   16	# OS version (SunOS IPSO Linux ... )
   17	UNAME_MAJOR = SunOS
   18	
   19	# OS version version (2.6 3.7 6.3 ... )
   20	UNAME_MINOR = 2.6
   21	
   22	# Hvilken firewall type (FW1  OSFW)
   23	FW_TYPE     = FW1
   24	
   25	# Hvilken firewall version (4.0 4.1 NG ... )
   26	FW_VER      = 4.1
   27	
   28	# belast denne RCPT med fejlpost
   29	RCPT        = fwsupport@uni-c.dk
   30	
   31	# Er deslogin instaleret - og på hvilken port (NONE 22 30 ... )
   32	DESLOGIN_PORT   = 30
   33	
   34	# Nick names (til ssh /td) for denne host ud over HOST_NAME
   35	NICK_NAMES  = ssi
   36	
   37	# Ekstra kundespecifikke filer
   38	EXTRA_FILES = 
# .fi
#	\fR
#	Alle variable er obligatoriske, med undtagelse af \fCEXTRA_FILES\fR,
#	\fCNICK_NAMES\fR samt \fCDESLOGIN_PORT\fR.
#
#	Har kunden nogle specielle ekstra dokumenter der skal med på en
#	backup, anføres de i \fCEXTRA_FILES\fR, f.eks. \fC/var/ace\fR.
#
#	Hvis kunden har noget installeret (f.eks. en ACE server) der kræver
#	en bestemt kommando udført, for at danne et dokument der skal på
#	backup, skal det ske på maskinen selv, f.eks. i forbindelse med
#	den daglige backup. Husk i den forbindelse at angive dette specielle
#	script i \fCEXTRA_FILES\fR, så det kommer med på backup'en :-)
# COMMANDS
#	\fCsh(1)\fR, \fCssh(1)\fR, \fCrsync(1)\fR, \fCsed(1)\fR og \fCawk(1)\fR.
# SE OGSÅ
#	Dokumentationen for UNIbackup.
# DIAGNOSTICS
#	Fejler programmet sendes en e-mail til den i konfigurationsfilen
#	anførte adresse.
# BUGS
#	Det er der sikkert. Der er bl.a. en fejl omkring etablering af
#	ssh forbindelsen, hvis firewall'ens nøgler er blevet ændret kræver
#	det en operatør indgriben; jeg gætter på, at processen vil hænge
#	for tid og evighed.
#
#	\fCrsync(1)\fR får alle filnavne på kommandolinien som argumentet
#	\fC`cat .all_files`\fR. Det betyder, at der ikke må findes filnavne
#	med blank-tegn, samt at der er en operativsystem specifik grænse for,
#	hvor stort dette argument må være.
# VERSION
#	$Date: 2003/08/13 13:40:31 $
# .br
#	$Revision: 1.17 $
# .br
#	$Source: /lan/ssi/projects/UNIfwbu/src/RCS/UNIfwbu.sh,v $
# .br
#	$State: Exp $
# HISTORY
#	Se \fCrlog\fR $Id: UNIfwbu.sh,v 1.17 2003/08/13 13:40:31 admin Exp $
# AUTHOR(S)
#	Niels Thomas Haugård
# .br
#	E-mail: thomas@haugaard.net
# .br
#	UNI\(buC
# .br
#	DTU, Building 304
# .br
#	DK-2800 Kgs. Lyngby
#--
