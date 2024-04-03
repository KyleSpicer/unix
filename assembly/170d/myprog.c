#include <stdio.h>

int main (int argc, char *argv[], char *envp[])
{
	for (int count = 0 ; count < argc ; count++)
	{
		printf("arg %d is %s\n", count, argv[count]);
	}

	for (int count = 0 ; envp[count] != NULL ; count++)
	{
		printf("env %d is %s\n", count, envp[count]);
	}

	return 0;
}
