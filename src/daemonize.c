/*
 * Based on http://stackoverflow.com/questions/17954432/creating-a-daemon-in-linux
 * with signal handling from http://www.thegeekstuff.com/2012/03/catch-signals-sample-c-code/
 * fra http://stackoverflow.com/questions/17954432/creating-a-daemon-in-linux
 * Signal handling, se http://www.thegeekstuff.com/2012/03/catch-signals-sample-c-code/
 */

#include "db2dps.h"

/*
 * Function to daemonize any (Linux) process
*/

void daemonize()
{
    pid_t pid;

    /* Fork off the parent process */
    pid = fork();

    /* An error occurred */
    if (pid < 0)
        exit(EXIT_FAILURE);

    /* Success: Let the parent terminate */
    if (pid > 0)
        exit(EXIT_SUCCESS);

    /* On success: The child process becomes session leader */
    if (setsid() < 0)
        exit(EXIT_FAILURE);

    /* Catch, ignore and handle signals */
    signal(SIGCHLD, SIG_IGN);
    signal(SIGHUP, SIG_IGN);

    /* Fork off for the second time*/
    pid = fork();

    /* An error occurred */
    if (pid < 0)
        exit(EXIT_FAILURE);

    /* Success: Let the parent terminate */
    if (pid > 0)
        exit(EXIT_SUCCESS);

    /* Set new file permissions */
    umask(0);

    /* Change the working directory to the root directory */
    /* or another appropriated directory */
    chdir("/");

    /* Close all open file descriptors */
    int x;
    for (x = sysconf(_SC_OPEN_MAX); x>0; x--)
    {
        close (x);
    }
}
