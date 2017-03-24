#include <stdio.h>
#include <stdlib.h>
#include <libpq-fe.h>


void do_exit(PGconn *conn) {
	
	PQfinish(conn);
	exit(1);
}

int main() {
	
	PGconn *conn = PQconnectdb("user=postgres password=hopsasa dbname=netflow");

	if (PQstatus(conn) == CONNECTION_BAD) {
		
		fprintf(stderr, "Connection to database failed: %s\n", PQerrorMessage(conn));
		do_exit(conn);
	}

	PGresult *res = PQexec(conn, "select flowspecruleid, direction, destinationprefix, sourceprefix, ipprotocol, srcordestport, destinationport, sourceport, icmptype, icmpcode, tcpflags, packetlength, dscp, fragmentencoding from flow.flowspecrules, flow.fastnetmoninstances");	
	
	if (PQresultStatus(res) != PGRES_TUPLES_OK) {
		printf("No data retrieved\n");		  
		PQclear(res);
		do_exit(conn);
	}	 
	
	int rows = PQntuples(res);
	
	for(int i=0; i<rows; i++) {
		printf("%s ", PQgetvalue(res, i, 0));
		printf("%s ", PQgetvalue(res, i, 1));
		printf("%s ", PQgetvalue(res, i, 2));
		printf("%s ", PQgetvalue(res, i, 3));
		printf("%s ", PQgetvalue(res, i, 4));
		printf("%s ", PQgetvalue(res, i, 5));
		printf("%s ", PQgetvalue(res, i, 6));
		printf("%s ", PQgetvalue(res, i, 7));
		printf("%s ", PQgetvalue(res, i, 8));
		printf("%s ", PQgetvalue(res, i, 9));
		printf("%s ", PQgetvalue(res, i, 10));
		printf("%s ", PQgetvalue(res, i, 11));
		printf("%s\n", PQgetvalue(res, i, 12));
	}	 

	PQclear(res);
	PQfinish(conn);

	return 0;
}
