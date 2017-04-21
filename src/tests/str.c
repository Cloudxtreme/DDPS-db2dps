#include <stdio.h>
#include <stdlib.h> //free

#define _GNU_SOURCE         /* See feature_test_macros(7) */

int asprintf(char **strp, const char *fmt, ...);

//Safer asprintf macro
#define Sasprintf(write_to, ...) { \
	char *tmp_string_for_extend = (write_to); \
	asprintf(&(write_to), __VA_ARGS__); \
	free(tmp_string_for_extend); \
}
//sample usage:
int main()
{
	int i=3;
	char *q = NULL;
	char *u = "user asdfasdf ";
	Sasprintf(q, "select * from tab");
	Sasprintf(q, "%s where col %i is not null and %s", q, i, u);
	printf("%s\n", q);
}
