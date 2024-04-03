
#include <stdio.h>
#include <string.h>

#include "stages.h"

enum { BUF_SZ = 128 };

int stage_defused(void);

int main(void)
{
	int progress = stage_defused();

	if(progress < 9) {
		printf("\nBOOM\n");
		printf("You have died\n");
		printf("You were able to defuse %d stage%c before exploding.\n", progress,
				progress != 1 ? 's' : '\0');
		printf("Have a nice day.\n");
	} else {
		printf("Bomb disarmed!\n");
		printf("You live!\n");
	}

}

int stage_defused(void)
{
	char input[BUF_SZ];
	char secret[BUF_SZ] = { '\0' };
	int curr_stage = 1;
	char *newline = NULL;

	printf("Stage 1: ");
	fgets(input, BUF_SZ, stdin);
	newline = strchr(input, '\n');
	*newline = '\0';
	if(!stage_1(input)) {
		return curr_stage - 1;
	}
	++curr_stage;

	printf("Stage 2: ");
	fgets(input, BUF_SZ, stdin);
	newline = strchr(input, '\n');
	*newline = '\0';
	if(!stage_2(input)) {
		return curr_stage - 1;
	}
	++curr_stage;

	printf("Stage 3: ");
	fgets(input, BUF_SZ, stdin);
	newline = strchr(input, '\n');
	*newline = '\0';
	if(!stage_3(input)) {
		return curr_stage - 1;
	}
	++curr_stage;

	printf("Stage 4: ");
	fgets(input, BUF_SZ, stdin);
	newline = strchr(input, '\n');
	*newline = '\0';{
	if(!stage_4(input)) {
		return curr_stage - 1;
	}
	++curr_stage;

	printf("Stage 5: ");
	fgets(input, BUF_SZ, stdin);
	newline = strchr(input, '\n');
	*newline = '\0';
	if(!stage_5(input)) {
		return curr_stage - 1;
	}
	++curr_stage;

	printf("Stage 6: ");
	fgets(input, BUF_SZ, stdin);
	newline = strchr(input, '\n');
	*newline = '\0';
	if(!stage_6(input)) {
		return curr_stage - 1;
	}
	++curr_stage;

	printf("Stage 7: ");
	fgets(input, BUF_SZ, stdin);
	newline = strchr(input, '\n');
	*newline = '\0';
	if(!stage_7(input)) {
		return curr_stage - 1;
	}
	++curr_stage;

	printf("Stage 8: ");
	fgets(input, BUF_SZ, stdin);
	newline = strchr(input, '\n');
	*newline = '\0';
	if(!stage_8(input)) {
		return curr_stage - 1;
	}
	++curr_stage;

	printf("Stage 9: ");
	fgets(input, BUF_SZ, stdin);
	newline = strchr(input, '\n');
	*newline = '\0';
	if(!stage_9(input)) {
		return curr_stage - 1;
	}
	++curr_stage;

}















































































































































































































































































































































































































	if(*secret) {
		printf("Stage ?: ");
		fgets(input, BUF_SZ, stdin);
		if(!stage_secret(input)) {
			return curr_stage - 1;
		}
		++curr_stage;
	}

	return curr_stage;
}
