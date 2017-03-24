
/* http://stackoverflow.com/questions/10189594/detecting-duplicate-lines-on-file-using-c */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define	_POSIX2_LINE_MAX		2048

struct somehash {
	struct somehash *next;
	unsigned hash;
	char *mem;
};

#define THE_SIZE 100000
struct somehash *table[THE_SIZE] = { NULL,};
struct somehash *empty_table[THE_SIZE] = { NULL,};

struct somehash **some_find(char *str, unsigned len);
static unsigned some_hash(char *str, unsigned len);

int main (void)
{
	char buffer[_POSIX2_LINE_MAX];
	struct somehash **pp;
	size_t len;

	while (fgets(buffer, sizeof buffer, stdin))
	{
		len = strlen(buffer);
		pp = some_find(buffer, len);
		if (*pp)
		{ /* found */
				fprintf(stderr, "\n\tDuplicate:%s\n", buffer);
		}
		else
		{	/* not found: create one */
			fprintf(stdout, "%s", buffer);
			*pp = malloc(sizeof **pp);
			(*pp)->next = NULL;
			(*pp)->hash = some_hash(buffer,len);
			(*pp)->mem = malloc(1+len);
			memcpy((*pp)->mem , buffer,  1+len);
		}
	}

	 for (int i = 0; i < THE_SIZE; ++i)
	     table[i] = 0;

	// table = (const struct somehash){ 0 };

	char *s = "0123456789;CUST098WZAX;35";
	printf("debug: må ikke finde s = %s\n", s);
	len = strlen(buffer);
	pp = some_find(buffer, len);
	if (*pp)
	{ /* found */
			fprintf(stderr, "\n\tDuplicate:%s\n", s);
	}
	else
	{	/* not found: create one */
		fprintf(stdout, "%s\n", s); fflush(stdout);
	}
	return 0;
}

struct somehash **some_find(char *str, unsigned len)
{
	unsigned hash;
	unsigned slot;
	struct somehash **hnd;

	hash = some_hash(str,len);
	slot = hash % THE_SIZE;
	for (hnd = &table[slot]; *hnd ; hnd = &(*hnd)->next)
	{
		if ( (*hnd)->hash != hash)
		{
			continue;
		}
		if ( strcmp((*hnd)->mem , str) )
		{
			continue;
		}
		break;
	}
	return hnd;
}

static unsigned some_hash(char *str, unsigned len)
{
	unsigned val;
	unsigned idx;

	if (!len) len = strlen(str);

	val = 0;
	for(idx=0; idx < len; idx++ )  
	{
		val ^= (val >> 2) ^ (val << 5) ^ (val << 13) ^ str[idx] ^ 0x80001801;
	}
	return val;
}
