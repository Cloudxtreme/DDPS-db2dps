#include <stdio.h>
#include <stdlib.h>
#include <libpq-fe.h>

void do_exit(PGconn *conn) {
    
    PQfinish(conn);
    exit(1);
}

int main() {
    
	/* https://www.postgresql.org/docs/8.1/static/libpq.html */
    PGconn *conn = PQconnectdb("user=postgres password=hopsasa dbname=netflow");	

    if (PQstatus(conn) == CONNECTION_BAD) {
        
        fprintf(stderr, "Connection to database failed: %s\n",
            PQerrorMessage(conn));
        do_exit(conn);
    }

    int ver = PQserverVersion(conn);

    printf("Server version: %d\n", ver);
    
    PQfinish(conn);

    return 0;
}
