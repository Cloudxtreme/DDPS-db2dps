/*
 * TODO:
 *       - finish this, then convert main to e.g. runner 
 *         and don't exit on ini file errors, just don't do anything but log the error(s)
 *       - replace main with main from daemonize.c
 *
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libpq-fe.h>
#include <unistd.h>
#include <syslog.h>

#include "iniparser.h"
#include "debug.h"

#define _GNU_SOURCE         /* See feature_test_macros(7) */

//Safer asprintf macro
#define Sasprintf(write_to, ...) { \
	char *tmp_string_for_extend = (write_to); \
	asprintf(&(write_to), __VA_ARGS__); \
	free(tmp_string_for_extend); \
}

int asprintf(char **strp, const char *fmt, ...);
void do_exit(PGconn *conn);

dictionary  *   ini ;
const char  *   db ;
const char  *   dbuser ;
const char  *   dbpass ;
const char  *   newrules ;
const char  *   remove_expired_rules ;
const char	*	hostlist;
const char	*	identity_file;
const char	*	sshuser;
const char	*	exabgp_pipe;

char	* ini_name = "db.ini";

int main(int argc, char * argv[])
{

	/* (1) Read configuration from INI file */

	#ifdef DO_DEBUG
	DEBUG_TRACE("%s starting in debug mode", argv[0] );
	#endif

	openlog(argv[0], LOG_PID|LOG_CONS, LOG_USER);

	ini = iniparser_load(ini_name);
	if (ini==NULL) {
		fprintf(stderr, "cannot parse file: %s\n", ini_name);
		syslog(LOG_INFO, "cannot parse file: %s", ini_name);
		return -1 ;
	}

	#ifdef DO_DEBUG
	DEBUG_TRACE("iniparser_dump" );
	iniparser_dump(ini, stdout);
	#endif

	/* exit if get db attributes fails */
	db = iniparser_getstring(ini, "db:dbname", NULL);
	if (db==NULL) { syslog(LOG_INFO, "failed reading dbname section from inifile: %s\n", ini_name); closelog(); return -1 ; }

	dbuser = iniparser_getstring(ini, "db:dbuser", NULL);
	if (dbuser==NULL) { syslog(LOG_INFO, "failed reading 'dbuser' from db section: %s\n", ini_name); closelog(); return -1 ; }

	dbpass = iniparser_getstring(ini, "db:dbpassword", NULL);
	if (dbpass==NULL) { syslog(LOG_INFO, "failed reading 'dbpassword' from db section: %s\n", ini_name); closelog(); return -1 ; }

	newrules = iniparser_getstring(ini, "db:newrules", NULL);
	if (newrules==NULL) { syslog(LOG_INFO, "failed reading 'newrules' from db section: %s\n", ini_name); closelog(); return -1 ; }

	remove_expired_rules = iniparser_getstring(ini, "db:remove_expired_rules", NULL);
	if (remove_expired_rules==NULL) { syslog(LOG_INFO, "failed reading 'remove_expired_rules' from db section: %s\n", ini_name); closelog(); return -1 ; }

	hostlist = iniparser_getstring(ini, "ssh:hostlist", NULL);
	if (hostlist==NULL) { syslog(LOG_INFO, "failed reading 'hostlist' from ssh section: %s\n", ini_name); closelog(); return -1 ; }

	identity_file = iniparser_getstring(ini, "ssh:identity_file", NULL);
	if (identity_file==NULL) { syslog(LOG_INFO, "failed reading 'identity_file' from ssh section: %s\n", ini_name); closelog(); return -1 ; }

	exabgp_pipe = iniparser_getstring(ini, "ssh:exabgp_pipe", NULL);
	if (exabgp_pipe==NULL) { syslog(LOG_INFO, "failed reading 'exabgp_pipe' from ssh section: %s\n", ini_name); closelog(); return -1 ; }

	sshuser = iniparser_getstring(ini, "ssh:sshuser", NULL);
	if (sshuser==NULL) { syslog(LOG_INFO, "failed reading 'sshuser' from ssh section: %s\n", ini_name); closelog(); return -1 ; }

	/* (2) Connect to the database */
	char * dblogin = NULL;

	Sasprintf(dblogin, "user=%s password=%s dbname=%s", dbuser, dbpass, db);

	syslog(LOG_INFO, "database: %s, user: %s, etc. read from %s", db, dbuser, ini_name );

	#ifdef DO_DEBUG
	DEBUG_TRACE("dblogin = %s", dblogin );
	#endif

	PGconn *conn = PQconnectdb(dblogin);

	if (PQstatus(conn) == CONNECTION_BAD) {
		syslog(LOG_INFO, "Connection to database failed: %s\n", PQerrorMessage(conn));
		#ifdef DO_DEBUG
		DEBUG_TRACE("Connection to database failed: %s", PQerrorMessage(conn));
		#endif
		PQfinish(conn);
		iniparser_freedict(ini);
		closelog();
		exit(EXIT_SUCCESS);
	}

	/* (3) retreive new rules - if any */
	PGresult *res = PQexec(conn, newrules);

	if (PQresultStatus(res) != PGRES_TUPLES_OK) {

		syslog(LOG_INFO, "No data retrieved\n");        
		PQclear(res);
		PQfinish(conn);
		iniparser_freedict(ini);
		closelog();
		exit(EXIT_SUCCESS);
	}    

	int nfields = PQnfields(res);
	int ntuples = PQntuples(res);

	/*
	**        flowspecruleid direction destinationprefix sourceprefix ipprotocol srcordestport destinationport sourceport icmptype icmpcode tcpflags packetlength dscp fragmentencoding
	** nfield 0              1         2                 3            4          5             6               7          8        9        10       11           12   13    
	*/
	const char *strings[] = {
		"flowspecruleid", "direction", "destinationprefix", "sourceprefix",
		"ipprotocol", "srcordestport", "destinationport", "sourceport",
		"icmptype", "icmpcode", "tcpflags", "packetlength",
		"dscp", "fragmentencoding"
		};

	//	TODO: reformat and send it to each exabgp with ssh
	// for each host in ssh:hostlist do;
	// ssh host 'cat $info > pipe' 
	for(int i = 0; i < ntuples; i++) {
		for(int j = 0; j < nfields; j++) {
			printf("ntuples[%d],nfields[%d] %s %s ", i, j, strings[j], PQgetvalue(res, i, j));
		}
		printf("\n");
	}
	PQclear(res);

	/* (4) process expired rules - if any */

	res = PQexec(conn, remove_expired_rules);

	if (PQresultStatus(res) != PGRES_TUPLES_OK) {

		syslog(LOG_INFO, "No data retrieved\n");        
		PQclear(res);
		PQfinish(conn);
		iniparser_freedict(ini);
		closelog();
		exit(EXIT_SUCCESS);
	}    

	nfields = PQnfields(res);
	ntuples = PQntuples(res);

	//	TODO: reformat and send it to each exabgp with ssh
	for(int i = 0; i < ntuples; i++) {
		for(int j = 0; j < nfields; j++) {
			printf("ntuples[%d],nfields[%d] %s %s ", i, j, strings[j], PQgetvalue(res, i, j));
		}
		printf("\n");
	}
	PQclear(res);


	/* (5) close down */

	PQfinish(conn);

	iniparser_freedict(ini);
	closelog();

	exit(EXIT_SUCCESS) ;
}

/*
 ** functions
 */

void do_exit(PGconn *conn) {

	PQfinish(conn);
	iniparser_freedict(ini);
	closelog();
	exit(EXIT_FAILURE);
}


/*
/* Documentation and  standard disclaimar
/*
/* Copyright (C) 2016 Niels Thomas Haugård
/* i2.dk | deic.dk | dtu.dk
/* http://www.dtu.dk/
/*
/* This program is free software; you can redistribute it and/or modify
/* it under the terms of the GNU General Public License as published by
/* the Free Software Foundation; either version 2 of the License, or
/* (at your option) any later version.
/*
/* This program is distributed in the hope that it will be useful,
/* but WITHOUT ANY WARRANTY; without even the implied warranty of
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
/* GNU General Public License for more details.
/*
/* You should have received a copy of the GNU General Public License 
/* along with this program; if not, write to the Free Software
/* Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
/*
/*++
/* NAME
/*	db2dps 1
/* SUMMARY
/*	Short description
/* PACKAGE
/*	file archive exercicer
/* SYNOPSIS
/*	db2dps options
/* DESCRIPTION
/*	\fIdb2dps\fR is used for ...
/*	Bla bla.
/*	More bla bla.
/* OPTIONS
/* .IP o
/*	I'm a bullet.
/* .IP o
/*	So am I.
/* COMMANDS
/*	
/* SEE ALSO
/*	
/* DIAGNOSTICS
/*	Whatever.
/* BUGS
/*	Probably. Please report them to the call-desk or the author.
/* VERSION
/*      $Date$
/* .br
/*      $Revision$
/* .br
/*      $Source$
/* .br
/*      $State$
/* HISTORY
/*	$Log$
/* AUTHOR(S)
/*	Niels Thomas Haugård
/* .br
/*	E-mail: thomas@haugaard.net
/* .br
/*	UNI-C
/* .br
/*	DTU, Building 305
/* .br
/*	DK-2800 Kgs. Lyngby
/* .br
/*	Denmark
/*--
*/
