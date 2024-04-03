// gcc -m32 -g -fno-stack-protector -z execstack -no-pie cibo.c -o cibo

#include <stdio.h>

void getinput(void);

void main(int argc, char *argv[])
{
	getinput();
}

void getinput(void)
{
	char buffer[50];
	printf("Enter stuff: ");
	fgets(buffer, 150, stdin);
}
