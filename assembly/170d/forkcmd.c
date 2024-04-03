/* OrphanZombie.c v1.1
 * Written by Kenton Groombridge
 * Program capable of creating zombies and orphans.
 * If parent quits before child, then child becomes orphan.
 * If child quits before parent, then child becomes zombie.
 * v1.0 Initial release
 * v1.1 Added more verbose output
 */
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

int main(int argc, char *argv[], char *envp[])
{
    pid_t child_pid, wpid;
    int status = 0;

    if (argc == 2)
    {
        // Convert the text on the command line to integers required by sleep();

        pid_t child_pid = fork(); // Fork returns child process id to parent process

        if (child_pid > 0) // If child has a PID, then this is the parent process
        {
            printf("I am the parent process wtih PID of %d, waiting for child command to complete.\n", getpid());

            // while ((wpid = wait(&status)) > 0); // Waits for all child processes

            waitpid(child_pid, &status, 0); // Parent process waits here for child to terminate.

            if (0 == status) // Verify child process terminated without error.
            {
                puts("The child process terminated normally.");
            }
            else
            {
                puts("The child process terminated with an error!.");
            }
        }
        else // Otherwise we are in the child process
        {
            printf("I am the child process and my PID is %d, and my PPID is %d\n", getpid(), getppid());

            printf("Executing command: %s\n", argv[1]);

            // if (execve("./getpid", argv, envp) == -1)
            if (execve(argv[1], argv, envp) == -1)
            {
                perror("Could not execve");
            }
        }
    }
    else
    {
        printf("Usage %s <command>\n", argv[0]);
        return 1;
    }

    return (0);
}
