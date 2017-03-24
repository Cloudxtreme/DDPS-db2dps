#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <syslog.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libpq-fe.h>
#include <unistd.h>
#include <syslog.h>
#include <ctype.h>
#include <getopt.h>
#include <errno.h> 
#include <stdarg.h>
#include <assert.h>
#include <errno.h>
#include <time.h>
#include <fcntl.h>

#include "license.h"
#include "iniparser.h"
#include "version.h"

#define PROGNAME "db2dps"

#define logit(format,...) do {																	\
		 char outstring[1024];																	\
		 if (verbose) {																			\
			time_t	 now;																		\
			time(&now);																			\
			 strftime(outstring, 100, "%H:%M:%S (%Y/%m/%d)", localtime(&now));					\
			 fprintf(stdout, "%s: %s line %6d [%d]: ", outstring, __FILE__, __LINE__, getpid());\
			 fprintf(stdout, format, ##__VA_ARGS__);										 	\
			 fputc('\n', stdout);															 	\
			 fflush(stdout);																 	\
		}																						\
} while(0)

#define _GNU_SOURCE         /* See feature_test_macros(7) */

int		asprintf(char **strp, const char *fmt, ...);

//Safer asprintf macro
#define Sasprintf(write_to, ...) { \
	char *tmp_string_for_extend = (write_to); \
	asprintf(&(write_to), __VA_ARGS__); \
	free(tmp_string_for_extend); \
}

/* Abbreviation for cleaner code. */
#define VA_NEXT(var, type)	((var) = (type) va_arg(args, type))

FILE *popen(const char *command, const char *type);

//                   announce | withdraw                                     %s ~= \\32$  ? %s\32 : %s
#define tcpudpfmt	"%s flow route %s { match { source 0.0.0.0/0; destination %s/32; destination-port %s; protocol %s; } then { discard; } } }"
#define icmpfmt		"%s flow route %s { match { protocol icmp; } then { discard; } } }"
#define ipdfmt		"%s flow route %s { match { protocol 0.0.0.0/0; } then { discard; } } }"


