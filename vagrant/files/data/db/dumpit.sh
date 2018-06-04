:

DIR=/tmp/`date +%s`

mkdir ${DIR}
chown postgres ${DIR}
chmod 700 ${DIR}

DB=netflow

su postgres -c "pg_dump -Cs ${DB}" > ${DIR}/schema_dump.sql

ls -l ${DIR}/schema_dump.sql

# system main data for icmp codes and types services protocols

for TABLE in flow.icmp_codes flow.icmp_types flow.services flow.protocols
do
	echo ${TABLE}:
	su postgres -c "pg_dump ${DB} --table=\"${TABLE}\"  -f ${DIR}/netflow_${TABLE}.sql"
	ls -l ${DIR}/netflow_${TABLE}.sql
done

# Import with
#	psql netflow -f filename 
