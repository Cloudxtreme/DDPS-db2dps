
/* http://coding.debuntu.org/c-implementing-str_replace-replace-all-occurrences-substring */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

char *strdup(const char *s);

char * str_replace ( const char *string, const char *substr, const char *replacement ){
  char *tok = NULL;
  char *newstr = NULL;
  char *oldstr = NULL;
  char *head = NULL;
 
  /* if either substr or replacement is NULL, duplicate string a let caller handle it */
  if ( substr == NULL || replacement == NULL ) return strdup (string);
  newstr = strdup (string);
  head = newstr;
  while ( (tok = strstr ( head, substr ))){
    oldstr = newstr;
    newstr = malloc ( strlen ( oldstr ) - strlen ( substr ) + strlen ( replacement ) + 1 );
    /*failed to alloc mem, free old string and return NULL */
    if ( newstr == NULL ){
      free (oldstr);
      return NULL;
    }
    memcpy ( newstr, oldstr, tok - oldstr );
    memcpy ( newstr + (tok - oldstr), replacement, strlen ( replacement ) );
    memcpy ( newstr + (tok - oldstr) + strlen( replacement ), tok + strlen ( substr ), strlen ( oldstr ) - strlen ( substr ) - ( tok - oldstr ) );
    memset ( newstr + strlen ( oldstr ) - strlen ( substr ) + strlen ( replacement ) , 0, 1 );
    /* move back head right after the last replacement */
    head = newstr + (tok - oldstr) + strlen( replacement );
    free (oldstr);
  }
  return newstr;
}

void usage(char *p){
  fprintf(stderr, "USAGE: %s string tok replacement\n", p );
}


int main( int argc, char **argv ){
  char *s1 = NULL; char *s2 = NULL;
  if( argc != 4 ) {
    usage(argv[0]);
    return 1;
  }
  s1 = str_replace( argv[1], argv[2], argv[3] );
  fprintf( stdout, "Old string: %s\nTok: %s\nReplacement: %s\nNew string: %s\n\n\n", argv[1], argv[2], argv[3], s1 );
  s2 = str_replace( s1, "stor", "enorm");
  fprintf( stdout, "Old string: %s\nTok: %s\nReplacement: %s\nNew string: %s\n", s1, "stor",  "enorm", s2 );
  free(s1);
  s1 = str_replace( s2, "enorm", "lille");
  fprintf( stdout, "Old string: %s\nTok: %s\nReplacement: %s\nNew string: %s\n", s1, "enorm",  "lille", s1 );
  free(s1);
  free(s2);
  return 0;
}

