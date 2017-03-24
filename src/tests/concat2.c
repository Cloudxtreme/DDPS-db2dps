/* http://stackoverflow.com/questions/8465006/how-to-concatenate-2-strings-in-c */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* 
char* concat(char *s1, char *s2)
{
    char *result = malloc(strlen(s1)+strlen(s2)+1);//+1 for the zero-terminator
    //in real code you would check for errors in malloc here
    strcpy(result, s1);
    strcat(result, s2);
    return result;
}
*/

char* concat(char *s1, char *s2)
{
    size_t len1 = strlen(s1);
    size_t len2 = strlen(s2);
    char *result = malloc(len1+len2+1);//+1 for the zero-terminator
    //in real code you would check for errors in malloc here
    memcpy(result, s1, len1);
    memcpy(result+len1, s2, len2+1);//+1 to copy the null-terminator
    return result;
}


int main()
{
	char* s = concat("derp", "herp");
	//do things with s
	printf("%s\n", s);
	free(s);//deallocate the string
}

/*

char * s = malloc(snprintf(NULL, 0, "%s %s", first, second) + 1);
sprintf(s, "%s %s", first, second);

*/

