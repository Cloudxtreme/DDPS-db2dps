//Modify YOUR_USERNAME and YOUR_PASSWORD.
//Note that dbname is YOUR_USERNAME in PostgreSQL system.
//drop table Hello if it exists in your database.
//
// compile it by
//   gcc -I/usr/include psql.c -L/usr/lib/ -lpq
//
// run it by
//   ./a.out

#include <stdlib.h>
#include <libpq-fe.h>

void error(char *mess)
{
  fprintf(stderr, "### %s\n", mess);
  exit(1);
}

int main(int argc, char **argv)
{
  int nfields, ntuples, i, j;
  PGresult *res;

  //connect to database
  PGconn *conn = PQconnectdb("host=sql.csic.umd.edu dbname=YOUR_USERNAME"
                             " user=YOUR_USERNAME password=YOUR_PASSWORD");
  if (PQstatus(conn) != CONNECTION_OK)
    error(PQerrorMessage(conn));

  //create a table
  res = PQexec(conn, "CREATE TABLE hello (message VARCHAR(32))");
  if (PQresultStatus(res) != PGRES_COMMAND_OK)
    error(PQresultErrorMessage(res));
  PQclear(res);

  //insert data
  res = PQexec(conn, "INSERT INTO hello VALUES ('Hello World!')");
  if (PQresultStatus(res) != PGRES_COMMAND_OK)
    error(PQresultErrorMessage(res));
  PQclear(res);

  //query the db
  res = PQexec(conn, "SELECT * FROM hello");
  if (PQresultStatus(res) != PGRES_TUPLES_OK)
    error(PQresultErrorMessage(res));
  nfields = PQnfields(res);
  ntuples = PQntuples(res);

  for(i = 0; i < ntuples; i++)
    for(j = 0; j < nfields; j++)
      printf("[%d,%d] %s\n", i, j, PQgetvalue(res, i, j));
  PQclear(res);

  //disconnect
  PQfinish(conn);
}
