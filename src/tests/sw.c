#include <stdio.h>
#include <string.h>

char * string = "XX";

int main()
{
	if (strcmp(string, "AAAA") == 0) 
	{
	  printf( "excelent\n");
	} 
	else if (strcmp(string, "BBBB") == 0)
	{
	  printf( "Good\n" );
	}
	/* more else if clauses */
	else /* default: */
	{
		printf("Hmm\n");
	}
}

