/* #ifdef DO_DEBUG */
#include <assert.h>
#include <errno.h>
#include <time.h>

#define DEBUG_TRACE(format,...) do {														\
		 time_t	 now;																		\
		 char outstring[100];																\
		 time(&now);																		\
		 strftime(outstring, 100, "%H:%M:%S (%Y/%m/%d)", localtime(&now));					\
		 fprintf(stdout, "%s: %s line %6d [%d]: ", outstring, __FILE__, __LINE__, getpid());\
		 fprintf(stdout, format, ##__VA_ARGS__);										 	\
		 fputc('\n', stdout);															 	\
		 fflush(stdout);																 	\
} while(0)
// #else
// #define MY_DEBUG_TRACE(...)	((void)0)
// #endif
