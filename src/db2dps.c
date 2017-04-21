/*
* TODO
*	fix problems with overlapping rules
*
* # Markdown pseudo code for db2dps
*
* ``db2dps`` is a small daemon running on the database server.
*
* ## Usage:
*
* ``db2dps`` _args_
* 		-v verbose and run in foreground
* 		-d daemonize
* 		-s <seconds> sleep time between database scan. Default is 20 seconds
*
* ``db2dps`` is stated from ``/etc/init.d``.
*
* Pseudo code:
*
*++
*```bash
*	read configuration || fail
*	check args, and EITHER run as daemon OR run in foreground
*
*	while true; 		# continue loop starts here
*	{
*		if [ we should exit ]
*		{
*			exit
*		}
*		 else {
*			sleep except on first loop
*		}
*		connect to database || exit fail
*		For each bgp-host do
*		{
*			if [ a full feed is required ]
*			{
*				query all records || continue
*			}
*			else {
*				query for NOT is activated and NOT expired records
*			}
*			for each record do {
*				convert record to rule usable by bgp-host
*				print rule to rulebase file
*				preserve record id for is activated record
*			}
*			copy rules to bgp-host || continue
*			query for expired AND is activated records
*			for each record do {
*				print rule to rulebase file
*				preserve record id for expired record
*			}
*			copy rulebase to bgp-host || warn
*			update database with all is activated records || warn
*			update database with all expired records     || warn
*		}
*	}
*
*```
*
*--
*/

#include "db2dps.h"

/* ANSI C requires at least one named parameter. */
char			*concat(const char *, ...);
char			*concatpath(const char *, const char *);

char			*default_inifile = "/opt/db2dps/etc/db.ini";
char 			*inifile = NULL;
dictionary		*ini ;

const char		*db  = NULL;					/* postgres database name */
const char		*dbuser  = NULL;				/* postgres login user */
const char		*dbpass  = NULL;				/* ... */
const char		*newrules  = NULL;				/* sql statement for new rules not yet enforced */
const char		*all_rules = NULL;				/* sql statement for all rules (fix bgp faileure */
const char		*remove_expired_rules  = NULL;	/* sql statement for updating db with enforced rules */
const char		*hostlist = NULL;				/* list of bgp instances reachable with ssh */
const char		*identity_file = NULL;			/* ssh identiy file */
const char		*sshuser = NULL;				/* ssh login user for exabgp */
const char		*filtertype = NULL;				/* filter type */
const char		*exabgp_pipe = NULL;			/* exabgp named pile on each exabgp instances */
const char		*datadir = NULL;				/* semaphore for exabgp instanses which require a full feed */
const char		*shutdown = NULL;				/* semaphore for requiring exit / nice shutdown */

const char		*blackhole = NULL;				/* */
const char		*ratelimit = NULL;				/* */

const char		*unblackhole = NULL;
const char		*unratelimit  = NULL;

const char		*update_rules_when_announced = NULL;				/* */
const char		*update_rules_when_expired   = NULL;				/* */
const char		*rulebasefile				 = NULL;				/* filename of rulebase from db.ini */

char			*dblogin = NULL;
PGconn 			*conn;
PGresult 		*res;

int				verbose = 0;
int				firstround = 1;

int				asprintf(char **strp, const char *fmt, ...);
void			exit_err(PGconn *conn);
void			usage();
void			daemonize();
char			**strsplit(const char* , const char*, size_t* n);
char			*strdup(const char *s);
char			*strtok(char *str, const char *delim);
char			*strtok_r(char *str, const char *delim, char **saveptr);
void			sig_handler(int signo);
int				access(const char *pathname, int mode);

int main(int argc, char * argv[])
{
	int verbose = 0;
	int rundaemon = 0;
	int sleeptime = 20;

	int nfields;
	int ntuples;

	char *rule = NULL;
	char *prev_rule = NULL;

	char *implemented_flowspecruleid = NULL;	// flowspecruleid which has been implemented
	char *expired_flowspecruleid = NULL;		// flowspecruleid which has expired

	int index;
	int c;
	opterr = 0;

	while ((c = getopt (argc, argv, "Vvds:f:")) != -1)
		switch (c)
		{
			case 'V':
				printf("version:       %s\n", VERSION); 
				printf("build date:    %s\n", build_date);
				printf("build_git_sha: %s\n", build_git_sha);
				exit(0);
			break;
			case 'v':
				verbose = 1;
				break;
			case 'd':
				rundaemon = 1;
				verbose = 0;
				break;
			case 's':
				sleeptime = atoi(optarg);
				break;
			case 'f':						// ment for testing: ini file with special crafted sql && bgp host as localhost with local file
				inifile = optarg;
				break;
			default:
				usage();
		}

	for (index = optind; index < argc; index++)
		printf ("Ignored non-option argument %s\n", argv[index]);

	if(! inifile)
		inifile = default_inifile;

	/* Open the log file */
	openlog(PROGNAME, LOG_PID|LOG_CONS, LOG_USER);

	/* see http://www.thegeekstuff.com/2012/03/catch-signals-sample-c-code/ */
	if (signal(SIGUSR1, sig_handler) == SIG_IGN)
		syslog(LOG_INFO, "can't catch SIGUSR1\n");

	/* Read configuration from INI file */
	ini = iniparser_load(inifile);
	if (ini==NULL) 
	{
		fprintf(stderr, "cannot parse file: %s\n", inifile); fflush(stdout);
		syslog(LOG_INFO, "cannot parse file: %s", inifile);
		syslog(LOG_INFO, "please fix the file: %s", inifile);
		exit_err(conn);	
	}

	// iniparser_dump(ini, stdout);

	/* exit if get db attributes fails */
	// TODO lav en exit_error funktion med print som syslog + stdout/stderr
	// se f.eks. http://stackoverflow.com/questions/16446136/is-there-a-way-to-redirect-syslog-messages-to-stdout

	db = iniparser_getstring(ini, "general:dbname", NULL);
	if (db==NULL) { syslog(LOG_INFO, "failed reading 'dbname' from section 'general' in inifile: %s\n", inifile); exit_err(conn) ; }

	dbuser = iniparser_getstring(ini, "general:dbuser", NULL);
	if (dbuser==NULL) { syslog(LOG_INFO, "failed reading 'dbuser' from db section: %s\n", inifile); exit_err(conn) ; }

	dbpass = iniparser_getstring(ini, "general:dbpassword", NULL);
	if (dbpass==NULL) { syslog(LOG_INFO, "failed reading 'dbpassword' from db section: %s\n", inifile); exit_err(conn) ; }

	newrules = iniparser_getstring(ini, "general:newrules", NULL);
	if (newrules==NULL) { syslog(LOG_INFO, "failed reading 'newrules' from db section: %s\n", inifile); exit_err (conn); }

	remove_expired_rules = iniparser_getstring(ini, "general:remove_expired_rules", NULL);
	if (remove_expired_rules==NULL) { syslog(LOG_INFO, "failed reading 'remove_expired_rules' from db section: %s\n", inifile); exit_err(conn) ; }

	hostlist = iniparser_getstring(ini, "general:hostlist", NULL);
	if (hostlist==NULL) { syslog(LOG_INFO, "failed reading 'hostlist' from ssh section: %s\n", inifile); exit_err(conn) ; }

	datadir = iniparser_getstring(ini, "general:datadir", NULL);
	if (datadir==NULL) { syslog(LOG_INFO, "failed reading 'datadir' from general section: %s\n", inifile); exit_err(conn) ; }

	all_rules = iniparser_getstring(ini, "general:all_rules", NULL);
	if (all_rules==NULL) { syslog(LOG_INFO, "failed reading 'all_rules' from db section: %s\n", inifile); exit_err(conn) ; }

	shutdown = iniparser_getstring(ini, "general:shutdown", NULL);
	if (datadir==NULL) { syslog(LOG_INFO, "failed reading 'shutdown' from general section: %s\n", inifile); exit_err(conn) ; }

	blackhole = iniparser_getstring(ini, "general:blackhole", NULL);
	if (blackhole==NULL) { syslog(LOG_INFO, "failed reading 'blackhole' from general section: %s\n", inifile); exit_err(conn) ; }

	ratelimit = iniparser_getstring(ini, "general:ratelimit", NULL);
	if (ratelimit==NULL) { syslog(LOG_INFO, "failed reading 'ratelimit' from general section: %s\n", inifile); exit_err(conn) ; }

	unblackhole = iniparser_getstring(ini, "general:unblackhole", NULL);
	if (unblackhole==NULL) { syslog(LOG_INFO, "failed reading 'unblackhole' from general section: %s\n", inifile); exit_err(conn) ; }

	unratelimit  = iniparser_getstring(ini, "general:unratelimit", NULL);
	if (ratelimit==NULL) { syslog(LOG_INFO, "failed reading 'unratelimit' from general section: %s\n", inifile); exit_err(conn) ; }

	update_rules_when_announced = iniparser_getstring(ini, "general:update_rules_when_announced", NULL);
	if (update_rules_when_announced==NULL) { syslog(LOG_INFO, "failed reading 'update_rules_when_announced' from general section: %s\n", inifile); exit_err(conn) ; }

	update_rules_when_expired = iniparser_getstring(ini, "general:update_rules_when_expired", NULL);
	if (update_rules_when_expired==NULL) { syslog(LOG_INFO, "failed reading 'update_rules_when_expired' from general section: %s\n", inifile); exit_err(conn) ; }

	rulebasefile = iniparser_getstring(ini, "general:rulebase", NULL);
	if (rulebasefile==NULL) { syslog(LOG_INFO, "failed reading 'rulebasefile' from general section: %s\n", inifile); exit_err(conn) ; }

	/* Prepare database connection */
	Sasprintf(dblogin, "host = 127.0.0.1 user=%s password=%s dbname=%s", dbuser, dbpass, db);

	syslog(LOG_INFO, "database: %s, user: %s, etc. read from %s", db, dbuser, inifile );

	/*
	**   flowspecruleid direction destinationprefix sourceprefix ipprotocol srcordestport destinationport sourceport icmptype icmpcode tcpflags packetlength dscp fragmentencoding
	** nfield 0         1         2                 3            4          5             6               7          8        9        10       11           12   13    
	*/
	const char *strings[] = {
		"flowspecruleid", "direction", "destinationprefix", "sourceprefix",
		"ipprotocol", "srcordestport", "destinationport", "sourceport",
		"icmptype", "icmpcode", "tcpflags", "packetlength",
		"dscp", "fragmentencoding"
	};

	if (verbose == 1) 
	{
		fprintf(stdout, "%s starting ... \n", PROGNAME );
		fflush(stdout);
	}

	if (rundaemon == 1)
	{
		verbose = 0;
		daemonize();
	}
	/* main loop */
	while (1)
	{
		if( access( shutdown, F_OK ) != -1 )
		{
			logit("shutdown file %s found, exiting", shutdown);
			syslog(LOG_INFO, "shutdown file %s found, exiting", shutdown);
			if (unlink (shutdown) != 0)
			{
				logit("failed to remove %s: %s", shutdown, strerror( errno ));
				syslog(LOG_INFO, "failed to remove %s: %s", shutdown, strerror( errno ));
			}
			break;
		}

		if (firstround == 1)
		{
			firstround = 0;
		}
		else 
		{
			sleep(sleeptime);	/* start by sleeping in case of error(s) in the ini file -- using continue */
		}

		/* Connect to the database */
		logit("connecting to database: %s as user: %s ... ", db, dbuser );
		syslog(LOG_INFO, "connecting to database: %s as user: %s ... ", db, dbuser );

		conn = PQconnectdb(dblogin);
		logit("PQconnectdb  ... ");

		if (PQstatus(conn) == CONNECTION_BAD)
		{
			logit("Connection to database failed: %s", PQerrorMessage(conn));
			syslog(LOG_INFO, "Connection to database failed: %s\n", PQerrorMessage(conn));
			exit_err(conn);
		}

		char **bgphost;
		size_t numhosts;
		char *filepath = NULL;

		logit("all bgp hosts: %s", hostlist);
		syslog(LOG_INFO, "all bgp hosts: %s", hostlist);

		bgphost = strsplit(hostlist, ", \t\n", &numhosts);
		for (size_t n = 0; n < numhosts; n++)
		{
			filepath = concatpath(datadir, bgphost[n]);

			logit("processing data for exabgp host %s", bgphost[n]);
			syslog(LOG_INFO, "processing data for exabgp host %s\n", bgphost[n]);

			char * tmpstr = NULL;
			tmpstr = concat(bgphost[n], ":identity_file", (char *) 0);

			identity_file = iniparser_getstring(ini, tmpstr, NULL);
			if (identity_file==NULL) { syslog(LOG_INFO, "failed reading 'identity_file' for host %s\n", bgphost[n]); exit_err(conn) ; }

			if (tmpstr != NULL)
				free(tmpstr);

			tmpstr = concat(bgphost[n], ":sshuser", (char *) 0);

			sshuser = iniparser_getstring(ini, tmpstr, NULL);
			if (sshuser==NULL) { syslog(LOG_INFO, "failed reading 'sshuser' for host %s\n", bgphost[n]); exit_err(conn) ; }

			if (tmpstr != NULL)
				free(tmpstr);

			tmpstr = concat(bgphost[n], ":filtertype", (char *) 0);
			filtertype = iniparser_getstring(ini, tmpstr, NULL);
			if (filtertype==NULL) { syslog(LOG_INFO, "failed reading 'filtertype' for host %s\n", bgphost[n]); exit_err(conn) ; }

			if (tmpstr != NULL)
				free(tmpstr);

			tmpstr = concat(bgphost[n], ":exabgp_pipe", (char *) 0);
			exabgp_pipe = iniparser_getstring(ini, tmpstr, NULL);
			if (exabgp_pipe==NULL) { syslog(LOG_INFO, "failed reading 'exabgp_pipe' for host %s\n", bgphost[n]); exit_err(conn) ; }

			if (tmpstr != NULL)
				free(tmpstr);

			// check if full feed is required by one or more exabgp instances
			if( access( filepath, F_OK ) != -1 )
			{
				logit("file %s found %s require full feed", filepath, bgphost[n]);
				if (unlink (filepath) != 0)
				{
					logit("failed to remove %s: %s", filepath, strerror( errno ));
					syslog(LOG_INFO, "failed to remove %s: %s", filepath, strerror( errno ));
				}

				logit("querying for all rules");
				res = PQexec(conn, all_rules);

				if (PQresultStatus(res) != PGRES_TUPLES_OK) {

					logit("No data retrieved");
					syslog(LOG_INFO, "No data retrieved\n"); 
					PQclear(res);
					continue;	/* continue main loop */
				}    

			}
			else	// query for new rules
			{
				logit("querying for new rules");
				syslog(LOG_INFO, "querying for new rules");

				res = PQexec(conn, newrules);
			}

			if (PQresultStatus(res) != PGRES_TUPLES_OK)
			{
				syslog(LOG_INFO, "No data retrieved\n");        
				PQclear(res);
				continue;		/* continue main loop */
			}    

			nfields = PQnfields(res);
			ntuples = PQntuples(res);

			logit("read %-d new rules from database", ntuples);
			syslog(LOG_NOTICE, "read %-d new rules from database", ntuples);

			// create rulebase file and print all rules to it
			FILE *rulebase;
			rulebase = fopen(rulebasefile, "w");
			int rules_to_send = 0;
			if (rulebase == NULL)
			{
				logit("Fatal: failed to create %s: %s", rulebasefile, strerror( errno ));
				syslog(LOG_INFO, "Fatal: failed to create %s: %s", rulebasefile, strerror( errno ));
				exit_err(conn);
			}

			logit("created rulebase file %s", rulebasefile);

			if(implemented_flowspecruleid != NULL)
			{
				free(implemented_flowspecruleid);
				implemented_flowspecruleid = NULL;	// reset counter
			}

			for(int i = 0; i < ntuples; i++)
			{
				char *flowspecruleid	= PQgetvalue(res, i, 0);
				char *direction			= PQgetvalue(res, i, 1);
				char *destinationprefix	= PQgetvalue(res, i, 2);
				char *sourceprefix		= PQgetvalue(res, i, 3);
				char *ipprotocol		= PQgetvalue(res, i, 4);
				char *srcordestport		= PQgetvalue(res, i, 5);
				char *destinationport	= PQgetvalue(res, i, 6);
				char *sourceport		= PQgetvalue(res, i, 7);
				char *icmptype			= PQgetvalue(res, i, 8);
				char *icmpcode			= PQgetvalue(res, i, 9);
				char *tcpflags			= PQgetvalue(res, i, 10);
				char *packetlength		= PQgetvalue(res, i, 11);
				char *dscp				= PQgetvalue(res, i, 12);
				char *fragmentencoding	= PQgetvalue(res, i, 13);

				if (implemented_flowspecruleid == NULL) {
					implemented_flowspecruleid = concat(flowspecruleid, (char *) 0);
				}
				else
				{
					char *s = concat(implemented_flowspecruleid, ",", flowspecruleid, (char *) 0);
					free(implemented_flowspecruleid);
					implemented_flowspecruleid = s;
				}

				// logit("| %-4s | %-16s | %-16s | %-8s | %-6s | %-6s | %-6s | %-10s |", flowspecruleid, sourceprefix, destinationprefix, ipprotocol, destinationport, icmptype, icmpcode, tcpflags);

				/* flowspec | blackhole or | ratelimit */
				rule = NULL;
				if (strcmp(filtertype,"flowspec") == 0)
				{
					if (ipprotocol && !ipprotocol[0]) {
						logit("fatal: ipprotocol is empty");
					}
					else if (strcmp(ipprotocol,"icmp") == 0)
					{
						Sasprintf(rule,icmpfmt, "announce", destinationport);
					}
					else if ((strcmp(ipprotocol,"udp") == 0) || (strcmp(ipprotocol,"tcp") == 0))
					{
						Sasprintf(rule,tcpudpfmt, "announce", flowspecruleid, destinationprefix, destinationport, ipprotocol);
					}
					else
					{
						Sasprintf(rule, ipdfmt, "announce", ipprotocol, destinationprefix);
					}
				}
				else if (strcmp(filtertype,"blackhole") == 0)
				{
						Sasprintf(rule, blackhole, destinationprefix);

				} else if (strcmp(filtertype,"ratelimit") == 0)
				{
						Sasprintf(rule, ratelimit, destinationprefix);

				} else
				{
					logit("unknown filtertype: %s for host %s - rule ignored", filtertype, bgphost[n]);
					continue;
				}

				if(prev_rule == NULL)
				{
						fprintf(rulebase, "%s\n", rule);
						logit("new block rule = %s", rule);
						rules_to_send ++;
						syslog(LOG_INFO, "new rule = %s", rule);
				}
				else
				{
					if (strcmp(rule,prev_rule) != 0)
					{
						syslog(LOG_INFO, "add rule = %s", rule);
						logit("add rule = %s", rule);
						fprintf(rulebase, "%s\n", rule);
						rules_to_send ++;
					}
					else
					{
						logit("block dupr = %s", rule);
						syslog(LOG_INFO, "dupl rule = %s", rule);
					}
					free(prev_rule);
					prev_rule = NULL;
				}
				if (rule != NULL)
				{
					prev_rule = rule;
					rule = NULL;
				}
			}
			if(rule != NULL)
			{
				free(rule);
				rule = NULL;
			}
				if(prev_rule != NULL)
				{
					free(prev_rule);
					prev_rule = NULL;
				}
				PQclear(res);

				// process expired rules - if any
				res = PQexec(conn, remove_expired_rules);

				if (PQresultStatus(res) != PGRES_TUPLES_OK)
				{
					syslog(LOG_INFO, "No data retrieved\n");        
					PQclear(res);
					PQfinish(conn);
					logit("PQfinish ... ");
					continue;
				}    

				nfields = PQnfields(res);
				ntuples = PQntuples(res);

				// https://tools.ietf.org/html/draft-liang-idr-bgp-flowspec-time-00 ?
				logit("read %-d expired rules for %s", ntuples, bgphost[n]);
				syslog(LOG_NOTICE, "read %-d expired rules for %s", ntuples, bgphost[n]);

				// update database for expired rules
				for(int i = 0; i < ntuples; i++)
				{
					char *flowspecruleid    = PQgetvalue(res, i, 0);
					char *direction			= PQgetvalue(res, i, 1);
					char *destinationprefix	= PQgetvalue(res, i, 2);
					char *sourceprefix		= PQgetvalue(res, i, 3);
					char *ipprotocol		= PQgetvalue(res, i, 4);
					char *srcordestport		= PQgetvalue(res, i, 5);
					char *destinationport	= PQgetvalue(res, i, 6);
					char *sourceport		= PQgetvalue(res, i, 7);
					char *icmptype			= PQgetvalue(res, i, 8);
					char *icmpcode			= PQgetvalue(res, i, 9);
					char *tcpflags			= PQgetvalue(res, i, 10);
					char *packetlength		= PQgetvalue(res, i, 11);
					char *dscp				= PQgetvalue(res, i, 12);
					char *fragmentencoding	= PQgetvalue(res, i, 13);

					if (expired_flowspecruleid == NULL) {
						expired_flowspecruleid = concat(flowspecruleid, (char *) 0);
					}
					else
					{
						char *s = concat(expired_flowspecruleid, ",", flowspecruleid, (char *) 0);
						free(expired_flowspecruleid);
						expired_flowspecruleid = s;
					}

					/* withdraw expired rules */
					rule = NULL;
					if (strcmp(filtertype,"flowspec") == 0)
					{
						if (ipprotocol && !ipprotocol[0]) {
							logit("fatal: ipprotocol is empty");
						}
						else if (strcmp(ipprotocol,"icmp") == 0)
						{
							Sasprintf(rule,icmpfmt, "withdraw", destinationport);
						}
						else if ((strcmp(ipprotocol,"udp") == 0) || (strcmp(ipprotocol,"tcp") == 0))
						{
							Sasprintf(rule,tcpudpfmt, "withdraw", flowspecruleid, destinationprefix, destinationport, ipprotocol);
						}
						else
						{
							Sasprintf(rule, ipdfmt, "writhdraw", ipprotocol, destinationprefix);
						}
					}
					else if (strcmp(filtertype,"blackhole") == 0)
					{
							Sasprintf(rule, unblackhole, destinationprefix);

					}
					else if (strcmp(filtertype,"ratelimit") == 0)
					{
							Sasprintf(rule, unratelimit, destinationprefix);

					} else
					{
						logit("unknown filtertype: %s for host %s - rule ignored", filtertype, bgphost[n]);
						continue;
					}

					if(prev_rule == NULL)
					{
							fprintf(rulebase, "%s\n", rule);
							logit("new withdraw = %s", rule);
					}
					else
					{
						if (strcmp(rule,prev_rule) != 0)
						{
							logit("withdraw rule = %s", rule);
							fprintf(rulebase, "%s\n", rule);
						}
						else
						{
							logit("withdraw dupr = %s", rule);
						}
						free(prev_rule);
						prev_rule = NULL;
					}
					if (rule != NULL)
					{
						prev_rule = rule;
						rule = NULL;
					}
				}
				if(rule != NULL)
				{
					free(rule);
					rule = NULL;
				}
				if(prev_rule != NULL)
				{
					free(prev_rule);
					prev_rule = NULL;
				}

				PQclear(res);
				fclose(rulebase);
				// rulebasefile will be truncated upon re-open
				// done with this host 

				/////////////////////////////////////////////////////////////////////////////////
				// This should be made with libssh2 and based on scp but the compilation fails //
				/////////////////////////////////////////////////////////////////////////////////

				char *cmd = NULL;
				const char *dst = NULL;

				tmpstr = concat(bgphost[n], ":exabgp_pipe", (char *) 0);

				dst = iniparser_getstring(ini, tmpstr, NULL);
				if (dst==NULL) { syslog(LOG_INFO, "failed reading 'exabgp_pipe' for host %s\n", bgphost[n]); exit_err(conn) ; }

				if (tmpstr != NULL)
					free(tmpstr);

				// timeout 10 ensures that we will not wait due to no listener on the pipe
				Sasprintf(cmd, "/usr/bin/timeout 10 /usr/bin/scp %s %s@%s:%s", rulebasefile, sshuser, bgphost[n], dst);

				/*
				* Dear maintainer:
				* Once you afe donw trying to 'optimize' this code, and have realized what a terrible
				* mistake that was, please increment the following counter as a warning to the next
				* guy:
				*	togal_hours_wasted = 8
				*/
				int pclose(FILE *stream);
				if (rules_to_send != 0)
				{
					syslog(LOG_INFO, "sending %d rules %s", rules_to_send, bgphost[n]);
					FILE *fp;
					char path[1035];
					fp = popen(cmd, "r");
					if (fp == NULL)
					{
						printf("Failed to run command\n" );
						exit(1);
					}
					while (fgets(path, sizeof(path)-1, fp) != NULL)
					{
						printf("%s", path);
					}

					int status = WEXITSTATUS(pclose(fp));
					if( WIFEXITED(status) != 0)
					{
						syslog(LOG_INFO, "copy rulebase %s to host %s exit code %i ok", rulebasefile, bgphost[n], status);
						logit("copy rulebase %s to host %s exit code %i ok", rulebasefile, bgphost[n], status);
					}
					else if( WIFSIGNALED(status) != 0)
					{
						// Child is terminated by a signal
						unsigned int sig_no = WTERMSIG(status);	// see http://stackoverflow.com/questions/3270307/how-do-i-get-the-lower-8-bits-of-int
						syslog(LOG_INFO, "copy rulebase %s to host %s exit code %i failed: killed by signal %i", rulebasefile, bgphost[n], status, sig_no & 0xFF);
						logit("copy rulebase %s to host %s exit code %i failed: killed by signal %i", rulebasefile, bgphost[n], status, 256/sig_no);
					}

					if (tmpstr != NULL)
						free(tmpstr);

					rules_to_send = 0;
				}
				else
				{
					syslog(LOG_INFO, "not sending %d rules to %s", rules_to_send, bgphost[n]);
					rules_to_send = 0;
				}
				if (cmd != NULL)
				{
					free(cmd);
					cmd = NULL;
				}

		free(bgphost[n]);

		if (filepath != NULL)
			free(filepath);
		}
		if (bgphost != NULL)
				free(bgphost);

		logit("all hosts in hostlist %s done", hostlist );

		/* update databse: flip all rules implemented */
		if (implemented_flowspecruleid != NULL)
		{
			logit("updating database with implemented rules");
			char *s = NULL;
			Sasprintf(s, update_rules_when_announced, implemented_flowspecruleid);

			res = PQexec(conn, s);
			if (PQresultStatus(res) != PGRES_COMMAND_OK)
			{
				logit("fatal: sql '%s' failed: %d", s, PQresultStatus(res));
				syslog(LOG_INFO, "fatal: sql '%s' failed: %d\n", s, PQresultStatus(res));
			}
			PQclear(res);

			if (s != NULL)
				free(s);
			free(implemented_flowspecruleid);
			implemented_flowspecruleid = NULL;
		}
		/* update database: flip all rules which are expired */
		if (expired_flowspecruleid != NULL)
		{
			logit("updating database with expired rules");
			char *s = NULL;
			Sasprintf(s, update_rules_when_expired, expired_flowspecruleid);

			res = PQexec(conn, s);
			if (PQresultStatus(res) != PGRES_COMMAND_OK)
			{
				logit("fatal: sql '%s' failed: %d", s, PQresultStatus(res));
				syslog(LOG_INFO, "fatal: sql '%s' failed: %d\n", s, PQresultStatus(res));
			}
			PQclear(res);

			if (s != NULL)
				free(s);
			free(expired_flowspecruleid);
			expired_flowspecruleid = NULL;
		}

		PQfinish(conn);
		logit("PQfinish ... ");
		logit("data processed, sleeping %d seconds ... ", sleeptime);
		syslog(LOG_NOTICE, "data processed, sleeping %d seconds ... ", sleeptime);
	}
	free(dblogin);
	iniparser_freedict(ini);
	closelog();
	return EXIT_SUCCESS;
}

/*
 ** functions
 */

void sig_handler(int signo)
{
    if (signo == SIGUSR1)
        syslog(LOG_NOTICE, "received SIGUSR1, shuting down");
    else if (signo == SIGKILL)
        syslog(LOG_NOTICE, "received SIGKILL, shuting down");
    else if (signo == SIGSTOP)
        syslog(LOG_NOTICE, "received SIGSTOP, shuting down");
}

void exit_err(PGconn *conn) 
{
	PQfinish(conn);
	iniparser_freedict(ini);
	closelog();
	exit(EXIT_FAILURE);
}

void usage(void)
{
	printf("\nUsage:\n");
	printf("\t -f <filename> alternative inifile\n");
	printf("\t -v verbose and run in foreground\n");
	printf("\t -d daemonize\n");
	printf("\t -s <seconds> sleep time between database scan. Default is 20 seconds\n");
	exit (EXIT_SUCCESS);
}

