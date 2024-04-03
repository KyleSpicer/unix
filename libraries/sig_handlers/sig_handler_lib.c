/**
 * @file signal_handler_lib.c
 * @author CW2 Kyle Spicer
 *
 *  @brief Function definitions for establishing signal handlers and
 * managing signals.
 *
 * This source file contains the implementation of functions to
 * establish signal handlers for specified signal numbers, block and
 * unblock signals, and manage the running state of the program.
 *
 * @version 0.2
 * @date 2023-08-17
 *
 * @note : You can view all signals from terminal with 'kill -L' command
 *
 * @copyright Copyright (c) 2023
 *
 */

#include <bits/types/sig_atomic_t.h> // for sig_atomic_t
#include <errno.h>                   // for errno
#include <pthread.h>
#include <signal.h> // for sigprocmask, sigemptyset
#include <stdarg.h> // for va_end, va_arg, va_list
#include <stdio.h>  // for perror, NULL

#include "include/sig_handler_lib.h"

#define SIG_BLOCK 0

/**
 * @brief Represents a variable that can be safely accessed from both
 * signal handlers and the main program, ensuring atomicity
 * during read and write operations.
 *
 * @note: 'volatile' tells compiler not to optimize access to this
 * variable, as it can be modified asynchronously by a sig handler.
 *
 * @note: 'sig_atomic_t' type guarantees that read/write operations are
 * atomic, meaning they are executed as a single, indivisible
 * operation, making it safe to use in signal handlers.
 *
 */
volatile sig_atomic_t gb_is_running       = 0;
pthread_mutex_t       gb_is_running_mutex = PTHREAD_MUTEX_INITIALIZER;

int
establish_sig_handler(int signum, handler func)
{
    int result = 0;

    if ((signum < 1) || (signum > SIGRTMAX) || (NULL == func))
    {
        result = 1;
        goto EXIT_ESTABLISH_HANDLER;
    }

    struct sigaction sig_action = {
        .sa_handler = func,
        .sa_flags   = 0,
    };

    int sig_act_value = sigaction(signum, &sig_action, NULL);
    if (-1 == sig_act_value)
    {
        perror("sigaction");
        errno  = 0;
        result = 1;
        goto EXIT_ESTABLISH_HANDLER;
    }
    pthread_mutex_lock(&gb_is_running_mutex);
    gb_is_running = 1;
    pthread_mutex_unlock(&gb_is_running_mutex);

EXIT_ESTABLISH_HANDLER:
    return result;
}

int
block_signals(int num_signals, ...)
{
    sigset_t mask   = { 0 };
    int      result = 0;

    result = sigemptyset(&mask);
    if (-1 == result)
    {
        perror("sigemptyset");
        errno  = 0;
        result = 1;
        goto EXIT_BLOCK_SIGNALS;
    }

    va_list signal_list;
    va_start(signal_list, num_signals);

    for (int i = 0; i < num_signals; i++)
    {
        int signum = va_arg(signal_list, int);

        result = sigaddset(&mask, signum);
        if (-1 == result)
        {
            perror("sigaddset");
            errno = 0;
            va_end(signal_list);
            goto EXIT_BLOCK_SIGNALS;
        }
    }

    va_end(signal_list);

    result = sigprocmask(SIG_BLOCK, &mask, NULL);
    if (-1 == result)
    {
        perror("sigpromask");
        errno  = 0;
        result = 1;
    }

EXIT_BLOCK_SIGNALS:
    return result;
}

int
unblock_signals(int num_signals, ...)
{
    sigset_t mask   = { 0 };
    int      result = 0;

    result = sigemptyset(&mask);
    if (-1 == result)
    {
        perror("sigemptyset");
        errno  = 0;
        result = 1;
        goto EXIT_UNBLOCK_SIGNALS;
    }

    va_list signal_list;
    va_start(signal_list, num_signals);

    for (int i = 0; i < num_signals; i++)
    {
        int signum = va_arg(signal_list, int);

        result = sigaddset(&mask, signum);
        if (-1 == result)
        {
            perror("sigaddset");
            errno = 0;
            va_end(signal_list);
            goto EXIT_UNBLOCK_SIGNALS;
        }
    }

    va_end(signal_list);

    result = sigprocmask(SIG_UNBLOCK, &mask, NULL);
    if (-1 == result)
    {
        perror("sigprocmask");
        errno  = 0;
        result = 1;
        goto EXIT_UNBLOCK_SIGNALS;
    }

EXIT_UNBLOCK_SIGNALS:
    return result;
}

int
block_all_signals(void)
{
    sigset_t mask   = { 0 };
    int      result = 0;

    result = sigfillset(&mask);
    if (-1 == result)
    {
        perror("sigfillset");
        result = 1;
        goto EXIT_BLOCK_ALL_SIGNALS;
    }

    result = sigprocmask(SIG_BLOCK, &mask, NULL);
    if (-1 == result)
    {
        perror("sigprocmask");
        result = 1;
        goto EXIT_BLOCK_ALL_SIGNALS;
    }

EXIT_BLOCK_ALL_SIGNALS:
    return result;
}

int
unblock_all_signals(void)
{
    sigset_t mask   = { 0 };
    int      result = 0;
    result          = sigemptyset(&mask);
    if (-1 == result)
    {
        perror("sigemptyset");
        result = 1;
        goto EXIT_UNBLOCK_ALL_SIGNALS;
    }

    result = sigprocmask(SIG_UNBLOCK, &mask, NULL);
    if (-1 == result)
    {
        perror("sigprocmask");
        result = 1;
        goto EXIT_UNBLOCK_ALL_SIGNALS;
    }

EXIT_UNBLOCK_ALL_SIGNALS:
    return result;
}

bool
is_program_running(void)
{
    bool b_result = false;

    pthread_mutex_lock(&gb_is_running_mutex);
    b_result = (gb_is_running != 0);
    pthread_mutex_unlock(&gb_is_running_mutex);

    return b_result;
}

void
stop_program(void)
{

    pthread_mutex_lock(&gb_is_running_mutex);
    gb_is_running = 0;
    pthread_mutex_unlock(&gb_is_running_mutex);
}

void
signal_handler(int sig)
{
    if ((!sig) || (1 > sig) || (SIGRTMAX < sig))
    {
        return;
    }

    if (SIGINT == sig || SIGQUIT == sig)
    {
        pthread_mutex_lock(&gb_is_running_mutex);
        gb_is_running = 0;
        pthread_mutex_unlock(&gb_is_running_mutex);
    }

} /* main_signal_handler */

void
block_signal(int signum)
{
    if ((signum < 1) || (signum > SIGRTMAX))
    {
        return;
    }

    sigset_t set = { 0 };
    sigemptyset(&set);
    sigaddset(&set, signum);

    if (-1 == sigprocmask(SIG_BLOCK, &set, NULL))
    {
        perror("sigprocmask");
        return;
    }

} /* block_signal() */

/*** end of file ***/
