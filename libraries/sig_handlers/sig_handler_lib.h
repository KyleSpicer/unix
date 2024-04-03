/**
 * @file signal_handler_lib.h
 * @author CW2 Kyle Spicer
 *
 * @brief Header file defining functions for establishing signal handlers and
 * managing signals.
 *
 * This header file provides functions to establish signal handlers for
 * specified signal numbers, block and unblock signals, and check the
 * state of the program. It also includes the definition of the 'handler'
 * function pointer type used for signal handlers.
 *
 * @version 0.3
 * @date 2023-08-17
 *
 * @cite This library was built during the 170D Warrant Officer Basic Course
 * and inspiration for concepts implementered were from course material.
 *
 * @copyright Copyright (c) 2023
 *
 */
#ifndef SIGNALS_H
#define SIGNALS_H

#include <stdbool.h> // for bool

typedef void (*handler)(int);

/**
 * Establishes a signal handler for the specified signal number.
 *
 * @param signum The signal number for which to establish the handler.
 * @param func The function pointer to the signal handler.
 * @return 0 if the signal handler is established successfully, 1 otherwise.
 */
int establish_sig_handler(int sigsum, handler func);

/**
 * Blocks the specified signals, adding them to the current signal mask.
 *
 * @param num_signals The number of signals to block.
 * @param ... The variable list of signal numbers to block.
 */
int block_signals(int num_signals, ...);

/**
 * Unblocks the specified signals in the current process.
 *
 * @param num_signals The number of signals to unblock.
 * @param ... Variable number of signal numbers to unblock.
 */
int unblock_signals(int num_signals, ...);

/**
 * Block all signals in the current process.
 * @return 0 if all signals are blocked successfully, 1 otherwise.
 */
int block_all_signals(void);

/**
 * Unblock all signals in the current process.
 * @return 0 if all signals are unblocked successfully, 1 otherwise.
 *
 */
int unblock_all_signals(void);

/**
 * @brief Checks if the program is running.
 *
 * @return true if the program is running, false otherwise.
 */
bool is_program_running(void);

/**
 * @brief Stops the program.
 *
 */
void stop_program(void);

/**
 * @brief Signal handler function.
 *
 * @param sig The signal number.
 */
void signal_handler(int sig);

void block_signal(int signal);

#endif /* SIGNALS_H */

/*** end of file ***/
