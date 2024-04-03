#include <stdio.h>
#include <unistd.h>

int main ()
{
	int user_real = getuid();
	int user_euid = geteuid();
	printf("REAL UID: %d\n", user_real);
	printf("EFFECTIVE UID: %d\n", user_euid);

	int group_real = getgid();
	int group_euid = getegid();
	printf("REAL GID: %d\n", group_real);
	printf("EFFECTIVE GID: %d\n", group_euid);
}
