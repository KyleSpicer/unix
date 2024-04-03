/* OrphanZombie.c
 * Written by Kenton Groombridge
 * Program capable of creating zombies and orphans.
 * If parent quits before child, then child becomes orphan.
 * If child quits before parent, then child becomes zombie.
*/
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
	if (argc == 3)
	{
		// Convert the text on the command line to integers required by sleep();
		int parenttime = atoi(argv[1]);
		int childtime = atoi(argv[2]);

		// Fork returns child process id to parent process
		pid_t child_pid = fork();
 
		// If child has a PID, then this is the parent process 
		if (child_pid > 0)
		{
			printf("I am the parent my PID %d\n", getpid());
			// Sleep for the number of seconds passed for the first argument
			sleep(parenttime);

			if(parenttime < childtime)
			{
				printf("Terminating parent now, child becoming an orphan...\n");
			}
		}
		// Otherwise we are in the child process
		else
		{
			printf("I am the child my PID is %d\n", getpid());
			// Sleep for the number of seconds passed for the second argument
			sleep(childtime);
			
			if(parenttime > childtime)
			{
				printf("Terminating child now, becoming an zombie...\n");
			}
			exit(0);
		}
    		return 0;
	}
	else
	{
		printf("Usage %s parenttime childtime\n", argv[0]);
		return 1;
	}
}
