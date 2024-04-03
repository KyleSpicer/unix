#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

int main(void)
{
	pid_t mypid;

	mypid = getpid();
	
	printf("I am in the getpid command and my PID is %d.\n", mypid);

	return 0;
}
