# 
# sql strings as global vars
#

#
# Add new rule to the database: 'null' and 'false' will be corrected by the program
#
$addrule = << "END_OF_QUERY";
insert into flow.flowspecrules
(
   flowspecruleid, customerid, rule_name,
   administratorid,
   direction, validfrom, validto,
   fastnetmoninstanceid,
   isactivated, isexpired, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport,
   icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding, action, description
)
values
(
   (select coalesce(max(flowspecruleid),0)+1 from flow.flowspecrules), '__customerid', '__uuid',
   '__administratorid',
   'in', now(), now()+interval '__blocktime minutes',
   '__fastnetmoninstanceid',
   'false', 'false', '__dst', '__src', '__protocol', '__dport', '__dport', '__sport',
   '__icmp_type', '__icmp_code', '__flags', '__length', '__dscp', '__frag', '__action', '__description'
);
END_OF_QUERY

$newrules = <<'EOF';
SELECT
	flowspecruleid,
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
	flow.flowspecrules.fastnetmoninstanceid = flow.fastnetmoninstances.fastnetmoninstanceid
	AND not isexpired
	AND not isactivated
	AND mode = 'enforce'
ORDER BY
	validto DESC,
	validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport,
	sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding;
EOF

#
# query for all active rules in case an exabgp needs the full feed
#
$all_rules 			= <<'EOF';
SELECT
	flowspecruleid,
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
	flow.flowspecrules.fastnetmoninstanceid = flow.fastnetmoninstances.fastnetmoninstanceid
	AND mode = 'enforce'
ORDER BY
	validto DESC,
	validto, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding;
EOF

#
# once a rule has been announced the database needs to be updated with the 'isactivated' flag
#
$update_rules_when_announced	= <<'EOF';
UPDATE
	flow.flowspecrules set isactivated = TRUE where flowspecruleid in ( %s );
EOF

#
# Select expired rules from the database
#
$remove_expired_rules = <<'EOF';
SELECT
	flowspecruleid,
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
	flow.flowspecrules.fastnetmoninstanceid = flow.fastnetmoninstances.fastnetmoninstanceid
	AND isactivated
	AND not isexpired
	AND mode = 'enforce' AND now() >= validto order by validto DESC;
EOF

#
# update the database for rules which has expired. The %s will be calculated by the program
#
$update_rules_when_expired = <<'EOF';
UPDATE
	flow.flowspecrules set isexpired = TRUE, isactivated = FALSE
WHERE
	flowspecruleid in ( %s );
EOF


# end queries
#UPDATE
#	flow.flowspecrules set isexpired = TRUE where flowspecruleid in ( %s );

1;
