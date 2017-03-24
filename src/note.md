
# apt-get ...

Det kræver en række ekstra pakker bl.a.:

	sudo apt-get install libssh2-1-dev

Samt naturligvis source - se ``Makefile``



TODO:

  - få sql sætninger på plads (FTH)
  - overvej _dedublikering af regler mod exabgp_.
 


db2dps.c:

Fra http://doxygen.postgresql.org/fe-connect_8c_source.html (fe-connect.c):

	/*
	 *      PQconnectdbParams
	 *
	 * establishes a connection to a postgres backend through the postmaster
	 * using connection information in two arrays.
	 *
	 * The keywords array is defined as
	 *
	 *     const char *params[] = {"option1", "option2", NULL}
	 *
	 * The values array is defined as
	 *
	 *     const char *values[] = {"value1", "value2", NULL}
	 *
	 * Returns a PGconn* which is needed for all subsequent libpq calls, or NULL
	 * if a memory allocation failed.
	 * If the status field of the connection returned is CONNECTION_BAD,
	 * then some fields may be null'ed out instead of having valid values.
	 *
	 * You should call PQfinish (if conn is not NULL) regardless of whether this
	 * call succeeded.
	*/


