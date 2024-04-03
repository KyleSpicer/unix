/* OrphanZombie.c v1.1
 * Written by Kenton Groombridge
 * Program capable of creating zombies and orphans.
 * If parent quits before child, then child becomes orphan.
 * If child quits before parent, then child becomes zombie.
 * v1.0 Initial release
 * v1.1 Added more verbose output
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
		char command[100]; // Used to build command for system so we can display zombie process

		pid_t child_pid = fork();  // Fork returns child process id to parent process
 
		if (child_pid > 0)  // If child has a PID, then this is the parent process
		{
			printf("I am the parent process and my PID is %d\n", getpid());

			if(parenttime < childtime)
			{
				sleep(parenttime); // If child is going to be an orphan, then sleep parenttime
				printf("Terminating parent process now, child process becoming an orphan...\n");
			}
			else
			{
				sleep (childtime + 1); // Add a second to child time to give time for child to become a zombie
				snprintf(command, 100, "ps -p %d -o command,state,pid,ppid", child_pid); // Build command to display status
				system(command); // Execute the command we just build with snprintf() to display status
			}
		}
		else // Otherwise we are in the child process
		{
			printf("I am the child process and my PID is %d, and my PPID is %d\n", getpid(), getppid());
			
			if(parenttime > childtime)
			{
				sleep(childtime); // Wait so many seconds until attempting to quit
				printf("Terminating child process now, becoming an zombie...\n");
			}
			else
			{
				sleep(parenttime + 1); // Add a second to parenttime to give time for parent to completely go away
				printf("I am the orphan child process and my PID is %d, and my PPID is %d\n", getpid(), getppid());
			}
		}
	}
	else
	{
		printf("Usage %s parenttime childtime\n", argv[0]);
		return (1);
	}
	return (0);
}
