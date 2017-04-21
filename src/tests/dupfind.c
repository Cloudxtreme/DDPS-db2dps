
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
		
		unsigned int h = some_hash(buffer, len);

		if (*pp)
		{ /* found */
				fprintf(stderr, "Duplicate: %u, %s\n", h, buffer);
		}
		else
		{	/* not found: create one */
			fprintf(stdout, "%u, %s", h, buffer);
			*pp = malloc(sizeof **pp);
			(*pp)->next = NULL;
			(*pp)->hash = some_hash(buffer,len);
			(*pp)->mem = malloc(1+len);
			memcpy((*pp)->mem , buffer,  1+len);
		}
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
		printf("debug: hash=%u slot=%u\n", hash, slot);
		printf("debug: (*hnd)->mem str: %s != %s\n", (*hnd)->mem, str);
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
