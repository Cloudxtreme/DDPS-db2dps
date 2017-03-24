
#include <stdio.h>
#include <stdlib.h>

#include "db2dps.h"

char            *dblogin = NULL;

int             asprintf(char **strp, const char *fmt, ...);

char *cmd = NULL;
char *usr = "rnd";
char *hst = "localhost";
char *dst = "/tmp/destignation-append";
char *src = "/opt/db2dps/tmp/rulebase.txt";

// Sasprintf(cmd, "scp %s %s@%s:%s", src, usr, hst, dst);
// Sasprintf(cmd, "host = 127.0.0.1 user=%s", usr);

FILE *popen(const char *command, const char *type);
int pclose(FILE *stream);

int main( int argc, char *argv[] )
{
  FILE *fp;
  char path[1035];
  char *cmd = "/usr/bin/timeout 5 scp /tmp/source rnd@localhost:/tmp/destignation-append";
  fp = popen(cmd, "r");
  if (fp == NULL) {
    printf("Failed to run command\n" );
    exit(1);
  }
  while (fgets(path, sizeof(path)-1, fp) != NULL) {
    printf("%s", path);
  }
  pclose(fp);
  return 0;
}

