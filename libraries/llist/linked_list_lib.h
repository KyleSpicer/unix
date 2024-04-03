/**
 * @file llist.h
 * @author CW2 Kyle Spicer
 * @brief  Opaque Linked List Data Structure.
 *         With features to use as: linked list, stack, or queue.
 * @version 0.2
 * @date 2023-06-21
 *
 * @copyright Copyright (c) 2023
 *
 */

#ifndef LINKED_LIST_LIB_H
#define LINKED_LIST_LIB_H

// #include <pthread.h>
// #include <stdint.h>
#include <stdint.h> // for int8_t, uint64_t

typedef void (*user_free_func)(void *);
typedef void (*user_print_func)(void *);

typedef struct llist llist_t;

/**
 * @brief allocates memory to begin populating linked list
 *
 * @return llist_t*
 */

llist_t *llist_create(user_print_func print, user_free_func destroy);

/**
 * @brief checks the amount of nodes within llist
 *
 * @param llist
 * @return int - the amount of nodes within the llist
 */
int8_t is_llist_empty(llist_t *llist);

/**
 * @brief inserts a llist node into the front of a given llist
 *
 * @param llist
 * @param data
 */
void llist_insert_front(llist_t *llist, void *data);

/**
 * @brief inserts a llist node into the back of a given llist
 *
 * @param llist
 * @param data
 */
void llist_insert_back(llist_t *llist, void *data);

/**
 * @brief removes front node from a given llist
 *
 * @param llist
 * @return void * data
 */
void *llist_remove_front(llist_t *llist);

/**
 * @brief prints contents within llist according to function logic
 *
 * @param llist
 */
void llist_display(llist_t *llist);

/**
 * @brief returns the amount of nodes within a given llist
 *
 * @param llist
 * @return int
 */
uint64_t llist_size(llist_t *llist);

/**
 * @brief frees all memory allocation, sets container memory address to NULL
 *
 * @param llist
 */
void llist_destroy(llist_t **llist);

/**
 * @brief pushes an element onto the front of the linked list
 *
 * @param llist
 * @param data
 */
void llist_push(llist_t *llist, void *data);

/**
 * @brief removes and return the element from the front of the linked list
 *
 * @param llist
 * @return void*
 */
void *llist_pop(llist_t *llist);

/**
 * @brief enqueues an element at the end of the linked list
 *
 * @param llist
 * @param data
 */
void llist_enqueue(llist_t *llist, void *data);

/**
 * @brief dequeues and returns the element from the front of the linked list
 *
 * @param llist
 * @return void*
 */
void *llist_dequeue(llist_t *llist);

/**
 * @brief returns the data element at the front of the linked list without
 * removing it
 *
 * @param llist
 * @return void*
 */
void *llist_peek(llist_t *llist);

/**
 * @brief returns the data of the element at the end of the linked list without
 * removing it.
 *
 * @param llist
 * @return void*
 */
void *llist_peek_tail(llist_t *llist);

#endif /* LINKED_LIST_LIB_H */

/*** end of file ***/
