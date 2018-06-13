# 
# sql strings as global vars
#

#
# Add new rule to the database: 'null' and 'false' will be corrected by the program
#
$addrule = << "END_OF_QUERY";
insert into flow.flowspecrules
(
   uuid_flowspecruleid, uuid_customerid, rule_name,
   uuid_administratorid,
   direction, validfrom, validto,
   uuid_fastnetmoninstanceid,
   isactivated, isexpired, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport,
   icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding, action, description
)
values
(
   uuid_generate_v4(), '__customerid', '__uuid',
   '__uuid_administratorid',
   'in', now(), now()+interval '__blocktime minutes',
   '__fastnetmoninstanceid',
   'false', 'false', '__dst', '__src', '__protocol', '__dport', '__dport', '__sport',
   '__icmp_type', '__icmp_code', '__flags', '__length', '__dscp', '__frag', '__action', '__description'
);
END_OF_QUERY

$newrules = <<'EOF';
SELECT distinct uuid_flowspecruleid
   uuid_flowspecruleid,
   direction,
   destinationprefix,
   sourceprefix,
   ipprotocol,
   srcordestport,
   destinationport,
   sourceport,
   icmptype,
   icmpcode,
   tcpflags,
   packetlength,
   dscp,
   fragmentencoding,
   action,
   validfrom,
   validto
FROM
   flow.flowspecrules,
   flow.fastnetmoninstances
WHERE
   not isexpired
   AND not isactivated
ORDER BY
   validto DESC,
   validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport,
   sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding;
EOF

#
# query for all active rules in case an exabgp needs the full feed
#
$all_rules 			= <<'EOF';
SELECT distinct uuid_flowspecruleid
	uuid_flowspecruleid,
	direction,
	destinationprefix,
	sourceprefix,
	ipprotocol,
	srcordestport,
	destinationport,
	sourceport,
	icmptype,
	icmpcode,
	tcpflags,
	packetlength,
	dscp,
	fragmentencoding,
	action,
	validfrom,
	validto
FROM
	flow.flowspecrules,
	flow.fastnetmoninstances
WHERE
   not isexpired
ORDER BY
	validto DESC,
	validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding;
EOF

#
# once a rule has been announced the database needs to be updated with the 'isactivated' flag
#
$update_rules_when_announced	= <<'EOF';
UPDATE
	flow.flowspecrules set isactivated = TRUE where uuid_flowspecruleid in ( %s );
EOF

#
# Select expired rules from the database
#
$remove_expired_rules = <<'EOF';
SELECT distinct uuid_flowspecruleid
	uuid_flowspecruleid,
	direction,
	destinationprefix,
	sourceprefix,
	ipprotocol,
	srcordestport,
	destinationport,
	sourceport,
	icmptype,
	icmpcode,
	tcpflags,
	packetlength,
	dscp,
	fragmentencoding,
	action,
	validfrom,
	validto
FROM
	flow.flowspecrules,
	flow.fastnetmoninstances
WHERE
	isactivated
	AND not isexpired
    AND now() >= validto order by validto DESC;
EOF

#
# update the database for rules which has expired. The %s will be calculated by the program
#
$update_rules_when_expired = <<'EOF';
UPDATE
	flow.flowspecrules set isexpired = TRUE, isactivated = FALSE
WHERE
	uuid_flowspecruleid in ( %s );
EOF

$check_admin_rights_on_dst = << 'EOF';
select
    count(*)
from
    flow.administrators, flow.customernetworks
WHERE
    flow.administrators.uuid_customerid = flow.customernetworks.uuid_customerid
    and
    flow.administrators.uuid_administratorid = '__uuid_administratorid'
    and
    flow.administrators.valid = 'active'
    and
    flow.customernetworks.net = '__dst'
    and
    flow.customernetworks.customernetworkid = ANY ( "networks" );
EOF

# end queries

1;
