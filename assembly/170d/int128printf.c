#define __GLIBCXX_TYPE_INT_N_0 __int128
#define __GLIBCXX_BITSIZE_INT_N_0 128

#define uint128_t __uint128_t

#include <stdio.h>
#include <stdint.h>

int Mk128(char *str, __uint128_t *p128)
{
    // Handle sign.

    __int128 mult = 1;
    if (*str == '-') {
        mult = -1;
        str++;
    }

    // Collect digits into number, handling grouping.

    *p128 = 0;
    
    while (*str != '\0')
    {
        if (*str >= '0' && *str <= '9')
	{
            *p128 = *p128 * 10 + *str - '0';
        }
	else if (*str != ',' && *str != ' ' && *str != '.')
	{
            return 0;
        }

        str++;
    }

    // Adjust for sign and return.

    *p128 *= mult;
    return 1;
}

// Recursive printer for large numbers, with grouping.

void print128(__int128 x, char *sep)
{
     // Handle negatives.

    if (x < 0)
    {
        putchar('-');
        print128(-x, sep);
        return;
    }

    // Print the top section, we're on the last recursion.

    if (x < 1000)
    {
        printf("%d", (int)x);
        return;
    }

    // Otherwise recurse, then print this grouping.

    print128(x / 1000, sep);
    printf("%s%03d", sep, (int)(x % 1000));
}


uint128_t fib(uint64_t n)
{
    uint128_t m;

    /* implement fibonacci where n is the number to input and m 
     * is the calcualted value
     */

    return m;
}
 
int main(void)
{
    for (uint64_t n = 0 ; n <= 185 ; n++)
    {
        printf("P(%lu) is ", n);
	  print128(fib(n),  "");
	  puts("");
    }

    return 0;
}
