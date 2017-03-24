#include <stdio.h>
#define _GNU_SOURCE         /* See feature_test_macros(7) */
#include <stdio.h>
#include <stdlib.h>

void *malloc(size_t size);
void free(void *ptr);

int asprintf(char **strp, const char *fmt, ...);

#define Sasprintf(write_to, ...) { \
        char *tmp_string_for_extend = (write_to); \
        asprintf(&(write_to), __VA_ARGS__); \
        free(tmp_string_for_extend); \
}

char * s = NULL;
// char * fmt = "user=%s password=%s dbname=%s";
char * fmt = "announce flow route %s { match { source any destination %s destination-port %s proto %s; } then { discard; } } }";
char * dp = "10.0.0.0/24";
char * p = "80";
char * d = "6";

int main()
{
	Sasprintf(s, fmt, dp, dp, p, d);

	printf("%s\n", s);
	free(s);



	return(0);

}
