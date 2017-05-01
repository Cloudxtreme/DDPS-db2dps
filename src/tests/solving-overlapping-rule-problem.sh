#!/bin/bash
#
# $Header$
#
#	I think that by sorting on _expire time_ first (and all other database
#	parameters afterwards) it will be easy to match rules with an expire time
#	greater than ``now()`` and therefore avoid expiring all other nearly
#	matching rules.

newrules="select
	flowspecruleid,
	--direction,
	--destinationprefix,
	--sourceprefix,
	ipprotocol,
	--srcordestport,
	destinationport,
	--sourceport,
	--icmptype,
	--icmpcode,
	tcpflags,
	packetlength,
	--dscp,
	fragmentencoding,
	action,
    validfrom,
    validto
from
	flow.flowspecrules,
	flow.fastnetmoninstances
where
	flow.flowspecrules.fastnetmoninstanceid = flow.fastnetmoninstances.fastnetmoninstanceid
	--AND not isexpired
	--AND not isactivated
	AND mode = 'enforce'
order by
	validto DESC,
	validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding
	;
"

working="
select
    flowspecruleid,
    -- customernetworkid,
	-- direction,
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
"

INI=/opt/db2dps/src/db.ini

function main()
{

	DBHOST="127.0.0.1"



	QUERY=`sed '/newrulesdir/d; /^newrules/!d; s/newrules[\t ]*=//' ${INI}`
	QUERY=`sed '/^all_rules/!d; s/all_rules[\t ]*=//' ${INI}`

	USR=`sed '/^dbuser/!d; s/dbuser[\t ]*=//' ${INI}`
	PW=`sed '/^dbpassword/!d; s/dbpassword[\t ]*=//' ${INI}`
	DB=`sed '/^dbname/!d; s/dbname[\t ]*=//' ${INI}`

	USR="postgres"

	q=$newrules
	q=$QUERY

	cat <<- EOF

--------------------------------------------------------------------------------	
	hostname = ${DBHOST}
	database = $DB
	username = $USR
	password = .... 

	 QUERY = $QUERY
--------------------------------------------------------------------------------

EOF

#  .pgpass - hostname:port:database:username:password

psql -h ${DBHOST} -U ${USR} -v ON_ERROR_STOP=1 -w -d ${DB} << EOF

$q

EOF
	# So, If vaidto > now() then discard all duplet rules

	return 0
}

##################################################################
# main
##################################################################

main $*

exit 0

