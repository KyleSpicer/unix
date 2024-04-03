/**
 * @file thread_pool_lib.c
 * @author CW2 Kyle Spicer
 * @brief This file contains the implementation logic for a thread pool.
 *
 * @cite Inspiration for this threadpool came from the 170D Warrant
 * Officer Basic Course
 *
 * @version 0.1
 * @date 2023-08-17
 *
 * @copyright Copyright (c) 2023
 *
 */
#include <errno.h>     // for errno
#include <pthread.h>   // for pthread_mutex_unlock, pthread_m...
#include <semaphore.h> // for sem_post, sem_wait, sem_init
#include <stdbool.h>   // for true, bool, false
#include <stdint.h>    // for uint8_t
#include <stdio.h>     // for NULL, perror
#include <stdlib.h>    // for free, calloc

#include "include/thread_pool_lib.h"

/**
 * @brief represents a single task in the tpool's task queue
 *
 */
typedef struct task
{
    task_func_t  p_function;
    struct task *p_next;
    void        *argument;
} task_t;

struct tpool
{
    pthread_t      *p_workers; // worker thread array
    task_t         *p_task_queue;
    pthread_mutex_t p_queue_mutex;     // mutex for task queue
    pthread_cond_t  p_queue_condition; // condition var for task queue
    uint8_t         num_workers;
    bool            b_shutdown;
};

/**
 * @brief worker thread function retrieves tasks from task queue and executes
 *
 */
static void *worker_thread(void *arg);

tpool_t *
tpool_create(int num_workers)
{
    tpool_t *p_tpool = NULL;

    if (1 > num_workers)
    {
        goto EXIT_TPOOL_CREATE;
    }

    p_tpool = calloc(1, sizeof(tpool_t));
    if (NULL == p_tpool)
    {
        perror("tpool create calloc");
        errno = 0;
        goto EXIT_TPOOL_CREATE;
    }

    p_tpool->num_workers = num_workers;

    p_tpool->p_workers = calloc(num_workers, sizeof(pthread_t));
    if (NULL == p_tpool->p_workers)
    {
        perror("tpool create worker threads calloc");
        errno = 0;
        free(p_tpool); // Clean up allocated memory for tpool
        p_tpool = NULL;
        goto EXIT_TPOOL_CREATE;
    }

    pthread_mutex_init(&p_tpool->p_queue_mutex, NULL);
    pthread_cond_init(&p_tpool->p_queue_condition, NULL);

    for (int i = 0; i < num_workers; i++)
    {
        pthread_create(&p_tpool->p_workers[i], NULL, worker_thread, p_tpool);
    }

EXIT_TPOOL_CREATE:
    return p_tpool;
} /* tpool_create() */

void
tpool_enqueue(tpool_t *p_tpool, task_func_t p_task, void *arg)
{
    if ((NULL == p_tpool) || (NULL == p_task) || (NULL == arg))
    {
        return;
    }

    task_t *p_new_task = calloc(1, sizeof(task_t));
    if (NULL == p_new_task)
    {
        perror("tpool enqueue new task calloc");
        errno = 0;
        return;
    }

    p_new_task->p_function = p_task;
    p_new_task->argument   = arg;
    pthread_mutex_lock(&p_tpool->p_queue_mutex);

    if (NULL == p_tpool->p_task_queue)
    {
        p_tpool->p_task_queue = p_new_task;
    }

    else
    {
        task_t *p_current_task = p_tpool->p_task_queue;

        while (p_current_task->p_next)
        {
            p_current_task = p_current_task->p_next;
        }
        p_current_task->p_next = p_new_task;
    }

    // NOTE: signals worker thread to wake up and process new task
    pthread_cond_signal(&p_tpool->p_queue_condition);

    pthread_mutex_unlock(&p_tpool->p_queue_mutex);

} /* tpool_enqueue() */

void
tpool_shutdown(tpool_t **pp_tpool)
{
    if ((NULL == pp_tpool) || (NULL == *pp_tpool))
    {
        return;
    }

    pthread_mutex_lock(&(*pp_tpool)->p_queue_mutex);

    (*pp_tpool)->b_shutdown = true;
    pthread_cond_broadcast(&(*pp_tpool)->p_queue_condition);

    pthread_mutex_unlock(&(*pp_tpool)->p_queue_mutex);

    for (int i = 0; i < (*pp_tpool)->num_workers; i++)
    {
        pthread_join((*pp_tpool)->p_workers[i], NULL);
    }

    free((*pp_tpool)->p_workers);

    task_t *p_current_task = (*pp_tpool)->p_task_queue;
    while (p_current_task)
    {
        task_t *p_next_task = p_current_task->p_next;
        free(p_current_task);
        p_current_task = p_next_task;
    }

    free(*pp_tpool);
    *pp_tpool = NULL;
} /* tpool_shutdown */

/* worker thread function retrieves tasks from task queue and executes */
static void *
worker_thread(void *arg)
{
    tpool_t *p_tpool = arg;

    for (;;)
    {
        pthread_mutex_lock(&p_tpool->p_queue_mutex);

        while ((NULL == p_tpool->p_task_queue)
               && (false == p_tpool->b_shutdown))
        {
            pthread_cond_wait(&p_tpool->p_queue_condition,
                              &p_tpool->p_queue_mutex);
        }

        if (true == p_tpool->b_shutdown)
        {
            pthread_mutex_unlock(&p_tpool->p_queue_mutex);
            return NULL;
        }
        task_t *p_task = p_tpool->p_task_queue;

        if (NULL == p_task)
        {
            pthread_mutex_unlock(&p_tpool->p_queue_mutex);
            continue;
        }
        p_tpool->p_task_queue = p_task->p_next;

        pthread_mutex_unlock(&p_tpool->p_queue_mutex);

        p_task->p_function(p_task->argument);

        free(p_task);
    }
} /* worker_thread() */

/*** end of  file ***/
