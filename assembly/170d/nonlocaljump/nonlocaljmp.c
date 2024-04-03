#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>

void func(void);
jmp_buf place; // Defined here to ensure scope in main() and func()

int main()
{
    // First call returns 0, a later longjmp will return non-zero.
    if (setjmp(place) != 0)
    {
        puts("Returned using longjmp");
        exit(EXIT_SUCCESS);
    }

    func(); // This call will never return - it 'jumps' back above.
    puts("What! func returned!");

    return 0;
}

void func(void)
{
    puts("In func()");
    // Return to main. Looks like a second return from setjmp, returning 4!
    longjmp(place, 4);
    puts("What! longjmp returned!");
}
