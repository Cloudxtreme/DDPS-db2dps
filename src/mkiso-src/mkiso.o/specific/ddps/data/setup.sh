:

for f in 1_create_netwlow_db.sql 2_create_netflow_schema.sql
do
	 su postgres -c "psql -f $f"
done


for f in netflow_flow.icmp_codes.sql netflow_flow.icmp_types.sql netflow_flow.protocols.sql netflow_flow.services.sql
do
	 su postgres -c "psql netflow -f $f 2>/dev/null"		# ignore errors: it is based on a dump and may contain redundant information
done

