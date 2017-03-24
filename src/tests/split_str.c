#include <ctype.h>
#include <stdio.h>

/* http://codereview.stackexchange.com/questions/20722/split-up-a-string-into-whitespace-seperated-fields */

static inline char* next_token(char *p)
{
    while (isspace(*p)) {
        ++p;
    }
    return *p ? p : NULL;
}

static inline char* next_space(char *p)
{
    while (!isspace(*p) && *p) {
        ++p;
    }
    return *p ? p : NULL;
}

static int string_split(char *p, char* token[])
{
    int n = 0;
    while ((p = next_token(p)) != NULL) {
        token[n++] = p;
        if ((p = next_space(p)) == NULL) {
            break;
        }
        *p++ = '\0';
    }
    return n;
}

#define MAX_SIZE 1024

int main()
{
    char *av[MAX_SIZE];
    char string[] = "this	is,a;test";
    //int i, ac = makeargv(string, av, 2);
    int i;
    int ac = string_split(string, av);
    printf("The number of token is: %d\n", ac);
    for(i = 0; i < ac; i++)
        printf("\"%s\"\n", av[i]);

    return 0;
}
