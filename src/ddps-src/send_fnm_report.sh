#! /usr/bin/env bash

T=ww2

REPORT=/tmp/relport.html
/bin/rm -f $REPORT
ssh ${T} 'sudo /opt/db2dps/bin/fnmcfg -b ' > $REPORT
echo $?

H=`hostname`
D=`dnsdomainname`
RCPT="fwsupport@i2.dk"
FROM="\"SSI FastNetMon host monitor - ${H}.${D}\" <fwsupport@i2.dk>"
MAILHOST="office.ssi.i2.dk"

case $1 in
	"")	:
		if [ -s $REPORT ]; then
			SUBJECT="FastNetMon host status: ERRORS"
			/opt/UNImsp/bin/climail.pl -f "${FROM}" -m "${MAILHOST}" -r "${RCPT}" -l "${REPORT}" -s "${SUBJECT}"

		fi
	;;
	"sendreport")
		scp ww2:/tmp/tmpdir/report.html $REPORT
		SUBJECT="FastNetMon host status"
		/opt/UNImsp/bin/climail.pl -f "${FROM}" -m "${MAILHOST}" -r "${RCPT}" -l "${REPORT}" -s "${SUBJECT}"
	;;
	*)	:
esac

exit 0
