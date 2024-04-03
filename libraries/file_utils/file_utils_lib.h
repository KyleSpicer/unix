/**
 * @file file_utils_lib.h
 * @author CW2 Kyle Spicer
 *
 * @brief This file contains function prototypes for file input/output
 * operations such as: validating and opening specified files and retrieving
 * file sizes.
 *
 * @version 0.1
 * @date 2023-08-17
 *
 * @copyright Copyright (c) 2023
 *
 */
#ifndef FILE_IO
#define FILE_IO

#include <stdbool.h> // for bool, false, true
#include <stdio.h>   // for perror, NULL, fprintf, FILE, fopen

/**
 * @brief This function takes a file pointer as input and returns the
 * size of the file in bytes. It achieves this by using the
 * 'fstat' function to retrieve the file stats, including file
 * size, based on the file descriptor assosciated with the given pointer.
 *
 * @param h_file_ptr A pointer to the file to retrieve the size from.
 * @return The size of the file in bytes, or 0 if the file pointer is
 * NULL or if an error occurs.
 */
long get_file_size_bytes(FILE *h_file_ptr);

/**
 * @brief - opens file with given filename and mode, returns file pointer
 *
 * @param filename - name of file to open
 * @param mode - mode to open file ["r", "w", "a", etc...]
 * @return FILE* - file pointer to opened file or NULL if error occurred
 */
FILE *open_file(const char *filename, const char *mode);

/**
 * @brief Validate and open a file.
 *
 * This function performs several checks prior to opening and returning
 * a `FILE *` pointer to the specified file. It ensures that the file path
 * is valid and secure, verifies the file type, and performs necessary
 * error handling. If all checks pass, the function attempts to open the
 * file using the provided access mode.
 *
 * @param filename char array - file path to open and validate
 * @param mode mode to open file ["r", "w", "a", etc...]
 * @return FILE* file pointer to opened file or NULL if error occurred
 */
FILE *validate_and_open_file(char       *filename,
                             const char *mode,
                             const char *root_dir);

/**
 * @brief
 *
 * @param h_file_ptr
 * @return true
 * @return false
 */
bool is_file_binary(FILE *h_file_ptr);

#endif /* FILE_IO */

/*** end of file ***/
