/**
 * @file file_utils_lib.c
 * @author CW2 Kyle Spicer
 *
 * @brief This file contains the implementations of file utility functions.
 *
 * @version 0.1
 * @date 2023-08-17
 *
 * @copyright Copyright (c) 2023
 *
 */
#define _DEFAULT_SOURCE

#include <ctype.h>    // for isprint, isspace
#include <errno.h>    // for errno
#include <limits.h>   // for PATH_MAX
#include <stdio.h>    // for perror, NULL, fprintf, FILE, fopen
#include <stdlib.h>   // for realpath
#include <string.h>   // for strstr
#include <sys/stat.h> // for stat, fstat, lstat, S_ISDIR, S_ISREG

#include "include/file_utils_lib.h"

#define RECORD_SEP '\x1E'

long
get_file_size_bytes(FILE *h_file_ptr)
{
    long file_size_in_bytes = 0;

    if (NULL == h_file_ptr)
    {
        goto EXIT_FUNCTION;
    }

    struct stat p_file_stats = { 0 };

    int file_descriptor = fileno(h_file_ptr);
    if (0 > file_descriptor)
    {
        goto EXIT_FUNCTION;
    }

    if (0 > fstat(file_descriptor, &p_file_stats))
    {
        goto EXIT_FUNCTION;
    }

    file_size_in_bytes = p_file_stats.st_size;

EXIT_FUNCTION:
    return file_size_in_bytes;

} /* get_file_size_bytes() */

FILE *
open_file(const char *filename, const char *mode)
{
    if (NULL == filename || NULL == mode)
    {
        return NULL;
    }

    FILE *h_file_ptr = fopen(filename, mode);
    if (NULL == h_file_ptr)
    {
        perror("open file");
        errno = 0;
        return NULL;
    }

    return h_file_ptr;
} /* open_file() */

FILE *
validate_and_open_file(char *filename, const char *mode, const char *root_dir)
{
    FILE *h_file_ptr = NULL;

    if (NULL == filename || NULL == mode || NULL == root_dir)
    {
        goto EXIT_FUNCTION;
    }

    // base directory where the files are located
    char resolved_path[PATH_MAX] = { '\0' };

    if (NULL == realpath(filename, resolved_path))
    {
        perror("Unable to find path");
        errno = 0;
        goto EXIT_FUNCTION;
    }

    struct stat p_file_stats_t = { 0 };

    if (0 != stat(resolved_path, &p_file_stats_t))
    {
        perror("Unable to access file");
        errno = 0;
        goto EXIT_FUNCTION;
    }

    // check for directory traversal attacks
    if (NULL == strstr(resolved_path, root_dir))
    {
        fprintf(stderr, "Path not subdirectory of %s\n", root_dir);
        goto EXIT_FUNCTION;
    }

    if (0 != lstat(filename, &p_file_stats_t))
    {
        perror("lstat error occured");
        errno = 0;
        goto EXIT_FUNCTION;
    }

    if (!S_ISREG(p_file_stats_t.st_mode))
    {
        fprintf(stderr, "'%s' is not a regular file.\n", filename);
        goto EXIT_FUNCTION;
    }

    h_file_ptr = fopen(filename, mode);
    if (NULL == h_file_ptr)
    {
        perror("open file");
        errno = 0;
    }

    bool b_is_binary = is_file_binary(h_file_ptr);
    if (b_is_binary)
    {
        fprintf(stderr, "'%s' is a binary file.\n", filename);
        fclose(h_file_ptr);
        h_file_ptr = NULL;
    }

EXIT_FUNCTION:
    return h_file_ptr;
} /* validate_and_open_file*() */

bool
is_file_binary(FILE *h_file_ptr)
{
    int character = 0;
    while ((character = fgetc(h_file_ptr)) != EOF)
    {
        if (!isprint(character) && !isspace(character) && !RECORD_SEP)
        {
            rewind(h_file_ptr);
            return true; // File is binary
        }
    }
    rewind(h_file_ptr);
    return false; // File is not binary
} /* is_file_binary() */

/*** end of file ***/
