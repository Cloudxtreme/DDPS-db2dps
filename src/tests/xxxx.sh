#!/bin/bash
#
# $Header$
#
#--------------------------------------------------------------------------------------#
# TODO
#
#	I think that by sorting on _expire time_ first (and all other database
#	parameters afterwards) it will be easy to match rules with an expire time
#	greater than ``now()`` and therefore avoid expiring all other nearly matching
#	rules.
#
#--------------------------------------------------------------------------------------#

#
# Vars
#
MYDIR=/path/to/some/dir
MYNAME=`basename $0`
MY_LOGFILE=/var/log/somelogfile
VERBOSE=FALSE
TMPFILE=/tmp/${MYNAME}.tmp

INI=/opt/db2dps/src/db.ini

function main()
{

	Q=`sed '/^all_rules/!d; s/all_rules[\t ]*=//' ${INI}`
	U=`sed '/^dbuser/!d; s/dbuser[\t ]*=//' ${INI}`
	P=`sed '/^dbpassword/!d; s/dbpassword[\t ]*=//' ${INI}`
	D=`sed '/^dbname/!d; s/dbname[\t ]*=//' ${INI}`

	cat <<- EOF

	database = $D
	username = $U
	password = $P

	 query: all_rules:
	 Q = $Q

EOF

#  .pgpass - hostname:port:database:username:password

cat << EOF | psql -h localhost -U postgres -v ON_ERROR_STOP=1 -w -d netflow
select
    flowspecruleid,
    -- customernetworkid,
    -- rule_name,
    -- administratorid,
    -- direction,
    -- fastnetmoninstanceid,
    -- isactivated,
    -- isexpired,
    destinationprefix,
    sourceprefix,
    ipprotocol,
    srcordestport,
    destinationport,
    sourceport,
    -- icmptype,
    -- icmpcode,
    -- tcpflags,
    -- packetlength,
    -- dscp,
    -- fragmentencoding,
    validfrom,
    validto

from
    flow.flowspecrules,
    flow.fastnetmoninstances
where
    flow.flowspecrules.fastnetmoninstanceid = flow.fastnetmoninstances.fastnetmoninstanceid AND
    not isactivated AND
    mode = 'enforce'
order by
	-- BGP flowspec RFC 5575
	destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding,
	-- DB
	validto;

EOF

	# Eureka:
	#       If vaidto > now() then discard all duplet rules
	#

	return 0

}

##################################################################
#
# main
#
##################################################################

main $*

exit 0

