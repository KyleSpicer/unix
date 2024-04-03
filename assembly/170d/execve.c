#include <stdio.h>
#include <unistd.h>

int main(void)
{
  printf("Main program started\n");
  char* argv[] = { "First arg", "Second arg", NULL };
  char* envp[] = { "MYVAR=1", "MYVAR2=2", NULL };

  if (execve("./myprog", argv, envp) == -1)
  {
    perror("Could not execve");
  }

  sleep(20);

  return 1;
}
