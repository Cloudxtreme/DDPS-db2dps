
#include <stdio.h>
#include <stdlib.h>

FILE *popen(const char *command, const char *type);
int pclose(FILE *stream);

int main( int argc, char *argv[] )
{

  FILE *fp;
  char path[1035];

 /* se evt scp.c og brug (2) -- virker med pipe på server siden ;-) */
 /* test med tail -f /tmp/destignation-append */
 /* popen: hurtigere færdig end med libssh, men ringere programmering
           1) skriv rules til lokal fil - uendelig størrelse
		      send fil med scp til pipe på remote host
			  slet fil
		   2) overfør hver enkelt rule til remote host med ssh ... echo > ...

		   1=: ingen problemer med store regelsæt men langsomt / filbaseret
		       og filen skal trunkeres / slettes / skrives for hver host
			   eller der skal holde øje med om vi er færdige med loop'et
		   2=: klodset

		   vælger (2)

		   Se evt https://www.safaribooksonline.com/library/view/secure-programming-cookbook/0596003943/ch01s07.html

		   */
 // 1:  char *cmd = "ssh rnd@localhost echo  \"libssh stinks, so does popen and a lot of other things ... nqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq\" >> /tmp/destignation-append";

  char *cmd = "scp /tmp/source rnd@localhost:/tmp/destignation-append";

  /* Open the command for reading. */
  // fp = popen("/bin/ls /etc/", "r");
  fp = popen(cmd, "r");
  if (fp == NULL) {
    printf("Failed to run command\n" );
    exit(1);
  }

  /* Read the output a line at a time - output it. */
  while (fgets(path, sizeof(path)-1, fp) != NULL) {
    printf("%s", path);
  }

  /* close */
  pclose(fp);

  return 0;
}

