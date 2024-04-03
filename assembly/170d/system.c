#include <stdio.h>
#include <stdlib.h>


int main( int argc, char *argv[] )
{

  FILE *fp;
  char path[1035];

  if(system("ls /etc")) // problem is you can't capture the output
  {
    puts("Failed to run command\n" );
    exit(1);
  } 

  /* Open the command for reading. */
  fp = popen("ls /etc/", "r");
  if (fp == NULL)
  {
    puts("Failed to run command\n" );
    exit(1);
  }

  /* Read the output a line at a time - output it. */
  while (fgets(path, sizeof(path), fp) != NULL)
  {
    printf("%s", path);
  }

  /* close */
  pclose(fp);

  return 0;
}
