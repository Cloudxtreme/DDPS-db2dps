:

DIR=/tmp/datadir

mkdir ${DIR}
chown postgres ${DIR}
chmod 700 ${DIR}

DB=netflow

for TABLE in	flow.icmp_codes flow.icmp_types flow.services flow.protocols	\
				flow.administrators flow.customernetworkobjects 				\
				flow.customernetworks flow.customers flow.fastnetmon_conf		\
				flow.fastnetmoninstances flow.flowspecrules						\
				flow.globalnetworkobjectcidrs flow.globalnetworkobjects			\
				flow.globalserviceobjects flow.networkrights					\
				flow.protocols flow.services

do
    echo ${TABLE}:
    su postgres -c "pg_dump ${DB} --table=\"${TABLE}\"  -f ${DIR}/netflow_${TABLE}.sql"
    ls -l ${DIR}/netflow_${TABLE}.sql
done
