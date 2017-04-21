#!/bin/bash
#
# $Header$
#
#	I think that by sorting on _expire time_ first (and all other database
#	parameters afterwards) it will be easy to match rules with an expire time
#	greater than ``now()`` and therefore avoid expiring all other nearly
#	matching rules.

INI=/opt/db2dps/src/db.ini

function main()
{

	DBHOST="127.0.0.1"

	QUERY=`sed '/^all_rules/!d; s/all_rules[\t ]*=//' ${INI}`
	USR=`sed '/^dbuser/!d; s/dbuser[\t ]*=//' ${INI}`
	PW=`sed '/^dbpassword/!d; s/dbpassword[\t ]*=//' ${INI}`
	DB=`sed '/^dbname/!d; s/dbname[\t ]*=//' ${INI}`

	USR="postgres"

	cat <<- EOF

	hostname = ${DBHOST}
	database = $DB
	username = $USR
	password = .... 

	 query: all_rules:
	 QUERY = $QUERY

EOF

#  .pgpass - hostname:port:database:username:password

cat << EOF | psql -h ${DBHOST} -U ${USR} -v ON_ERROR_STOP=1 -w -d ${DB}
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
	validto DESC,
	validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding
	;

EOF
	# So, If vaidto > now() then discard all duplet rules

	return 0
}

##################################################################
# main
##################################################################

main $*

exit 0

