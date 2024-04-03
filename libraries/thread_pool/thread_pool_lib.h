/**
 * @file thread_pool_lib.h
 *
 * @author CW2 Kyle Spicer
 * @brief The header file contains necessary dependencies and declarations for
 * functions used in the thread_pool_lib.c file.
 *
 * @cite This library was constructed during the 170D Warrant Officer Basic
 * Course. Inspiration for this library came from course material.
 * @version 0.1
 * @date 2023-08-17
 *
 * @copyright Copyright (c) 2023
 *
 */
#ifndef THREAD_POOL_H
#define THREAD_POOL_H

typedef struct tpool tpool_t;
typedef void *(*task_func_t)(void *);

/**
 * @brief creates new thread pool with specified amount of workers
 *
 * @param num_workers
 * @return tpool_t*
 */
tpool_t *tpool_create(int num_workers);

/**
 * @brief adds a task to the thread pool task queue
 *
 */
void tpool_enqueue(tpool_t *p_tpool, task_func_t p_task, void *arg);

/**
 * @brief waits for all tasks in the tpool queue to complete, then shuts down
 * tpool and frees all allocated memory.
 *
 * @param pp_tpool
 */
void tpool_shutdown(tpool_t **pp_tpool);

#endif /* THREAD_POOL_H */

/*** end of file ***/
