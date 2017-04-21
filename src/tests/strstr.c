#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

int printf(const char *format, ...);
char *strndup(const char *s, size_t n);

char *strdup(const char *s);

size_t occurrences(const char *, const char *);
char *replace(const char *str, const char *sub, const char *replace);
void copy_string(char *, char *);

char * cmd = "announce flow route ${dst} { match { source any destination ${dst}; destination-port ${dport}; proto ${ipprotocol}; } then { discard; } } }";
char * dst_str = "${dst}";
char * dst = "10.0.0.0/23";
char * dport_str = "${dport}";
char * dport = "80";
char * ipp_str = "${ipprotocol}";
char * ipp = "6";

/*
 * Replace all occurrences of `sub` with `replace` in `str`
 */



int main() {
    char *s = NULL;
	char *t = NULL;
    s = replace(cmd, dst_str, dst);
	t = malloc(sizeof(s) + 1);
	copy_string(t,s);
    t = replace(s, dport_str, dport);
	free(s); s = malloc(sizeof(t) + 1);
    s = replace(t, ipp_str, ipp);
    printf("%s\n", s);
    free(s);
    free(t);

	

    return 0;
}

// strncpy(dst_arr, src_str, sizeof(dst_arr));

char * replace(const char *str, const char *sub, const char *replace)
{
	char *pos = (char *) str;
	int count = occurrences(sub, str);

	if (0 >= count) return strdup(str);

	int size = ( strlen(str) - (strlen(sub) * count) + strlen(replace) * count) + 1;

	char *result = (char *) malloc(size);
	if (NULL == result) return NULL;
	memset(result, '\0', size);
	char *current;
	while ((current = strstr(pos, sub)))
	{
		int len = current - pos;
		strncat(result, pos, len);
		strncat(result, replace, strlen(replace));
		pos = current + strlen(sub);
	}

	if (pos != (str + strlen(str)))
	{
		strncat(result, pos, (str - pos));
	}

	return result;
}

/*
 * Get the number of occurrences of `needle` in `haystack`
 */

size_t occurrences(const char *needle, const char *haystack) {
  if (NULL == needle || NULL == haystack) return -1;

  char *pos = (char *)haystack;
  size_t i = 0;
  size_t l = strlen(needle);
  if (l == 0) return 0;

  while ((pos = strstr(pos, needle))) {
    pos += l;
    i++;
  }

  return i;
}

void copy_string(char *target, char *source) {
   while (*source) {
      *target = *source;
      source++;
      target++;
   }
   *target = '\0';
}


/* http://stackoverflow.com/questions/779875/what-is-the-function-to-replace-string-in-c */

/*
// You must free the result if result is non-NULL.
char *str_replace(char *orig, char *rep, char *with) {
    char *result; // the return string
    char *ins;    // the next insert point
    char *tmp;    // varies
    int len_rep;  // length of rep
    int len_with; // length of with
    int len_front; // distance between rep and end of last rep
    int count;    // number of replacements

    if (!orig)
        return NULL;
    if (!rep)
        rep = "";
    len_rep = strlen(rep);
    if (!with)
        with = "";
    len_with = strlen(with);

    ins = orig;
    for (count = 0; tmp = strstr(ins, rep); ++count) {
        ins = tmp + len_rep;
    }

    // first time through the loop, all the variable are set correctly
    // from here on,
    //    tmp points to the end of the result string
    //    ins points to the next occurrence of rep in orig
    //    orig points to the remainder of orig after "end of rep"
    tmp = result = malloc(strlen(orig) + (len_with - len_rep) * count + 1);

    if (!result)
        return NULL;

    while (count--) {
        ins = strstr(orig, rep);
        len_front = ins - orig;
        tmp = strncpy(tmp, orig, len_front) + len_front;
        tmp = strcpy(tmp, with) + len_with;
        orig += len_front + len_rep; // move to next "end of rep"
    }
    strcpy(tmp, orig);
    return result;
}

*/
