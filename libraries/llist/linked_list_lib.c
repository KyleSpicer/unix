/**
 * @file linked_list_lib.c
 * @author CW2 Kyle Spicer
 * @brief Implementation of an Opaque Linked List Data Structure.
 *        Can be used as a regular linked list, stack, or queue.
 * @version 0.2
 * @date 2023-08-02
 *
 * @copyright Copyright (c) 2023
 *
 */

#include <pthread.h> // for pthread_mutex_lock, pthread_mutex_unlock, ...
#include <stdint.h>  // for uint64_t, int8_t
#include <stdio.h>   // for NULL
#include <stdlib.h>  // for calloc, free

#include "linked_list_lib.h"

typedef struct llist_node llist_node_t;

typedef struct llist_node
{
    void         *data;
    llist_node_t *next;
} llist_node_t;

typedef struct llist
{
    uint64_t        count;
    llist_node_t   *head;
    llist_node_t   *tail;
    user_print_func print;
    user_free_func  user_free;
    pthread_mutex_t mlock;
} llist_t;

/**
 * @brief Creates a new node for a linked list and initializes its data.
 *
 * @param data
 * @return llist_node_t*
 */
static llist_node_t *create_node(void *data);

llist_t *
llist_create(user_print_func print, user_free_func destroy)
{
    llist_t *llist = NULL;

    if ((NULL == print) || (NULL == destroy))
    {
        goto EXIT_LLIST_CREATE;
    }
    llist = calloc(1, sizeof(llist_t));
    if (NULL == llist)
    {
        goto EXIT_LLIST_CREATE;
    }

    llist->print     = print;
    llist->user_free = destroy;
    pthread_mutex_init(&llist->mlock, NULL);

EXIT_LLIST_CREATE:
    return llist;
} /* llist_create() */

int8_t
is_llist_empty(llist_t *llist)
{
    int8_t ret_val = 1;
    if (NULL == llist)
    {
        ret_val = -1;
        goto EXIT_IS_LLIST_EMPTY;
    }
    if (llist->count > 0)
    {
        ret_val = 0;
        goto EXIT_IS_LLIST_EMPTY;
    }

EXIT_IS_LLIST_EMPTY:
    return ret_val;

} /* is_llist_empty() */

void
llist_insert_front(llist_t *llist, void *data)
{
    if ((NULL == llist) || (NULL == data))
    {
        return;
    }
    llist_node_t *new_node = calloc(1, sizeof(llist_node_t));
    if (NULL == new_node)
    {
        return;
    }
    new_node->data = data;

    pthread_mutex_lock(&llist->mlock);
    if (!llist->tail)
    {
        llist->tail = new_node;
    }
    new_node->next = llist->head;
    llist->head    = new_node;
    llist->count++;
    pthread_mutex_unlock(&llist->mlock);
} /* llist_insert_front() */

void
llist_insert_back(llist_t *llist, void *data)
{
    if ((NULL == llist) || (NULL == data))
    {
        return;
    }

    llist_node_t *new_node = calloc(1, sizeof(llist_node_t));
    if (NULL == new_node)
    {
        return;
    }
    new_node->data = data;

    pthread_mutex_lock(&llist->mlock);

    if (NULL == llist->head)
    {
        llist->head = new_node;
    }
    else
    {
        llist_node_t *current = llist->head;

        while (NULL != current->next)
        {
            current = current->next;
        }
        current->next = new_node;
    }
    llist->count++;
    pthread_mutex_unlock(&llist->mlock);
} /* llist_insert_back() */

void *
llist_remove_front(llist_t *llist)
{
    llist_node_t *data = NULL;

    if ((NULL == llist) || (is_llist_empty(llist)))
    {
        goto EXIT_LLIST_REMOVE_FRONT;
    }

    pthread_mutex_lock(&llist->mlock);
    llist_node_t *temp = llist->head;
    llist->head        = temp->next;
    llist->count--;
    pthread_mutex_unlock(&llist->mlock);

    data = temp->data;
    free(temp);

EXIT_LLIST_REMOVE_FRONT:
    return (data);

} /* llist_remove_front() */

uint64_t
llist_size(llist_t *llist)
{
    uint64_t ret_val = 0;

    if (NULL == llist)
    {
        ret_val = -1;
        goto EXIT_LLIST_SIZE;
    }

    ret_val = llist->count;
EXIT_LLIST_SIZE:
    return ret_val;
} /* llist_size() */

void
llist_destroy(llist_t **llist)
{
    if ((NULL == llist) || (NULL == *llist))
    {
        return;
    }
    llist_node_t *temp = (*llist)->head;
    while (temp)
    {
        (*llist)->head = temp->next;
        (*llist)->user_free(temp->data);
        free(temp);
        temp = (*llist)->head;
    }
    free(*llist);
    llist = NULL;
} /* llist_destroy() */

void
llist_push(llist_t *llist, void *data)
{
    if ((NULL == llist) || (NULL == data))
    {
        return;
    }

    llist_node_t *new_node = create_node(data);
    if (NULL == new_node)
    {
        return;
    }

    pthread_mutex_lock(&llist->mlock);

    if (NULL == llist->tail)
    {
        llist->tail = new_node;
    }
    new_node->next = llist->head;
    llist->head    = new_node;
    llist->count++;

    pthread_mutex_unlock(&llist->mlock);
} /* llist_push() */

void *
llist_pop(llist_t *llist)
{
    return llist_remove_front(llist);
} /* llist_pop() */

void
llist_enqueue(llist_t *llist, void *data)
{
    if ((NULL == llist) || (NULL == data))
    {
        return;
    }

    llist_node_t *new_node = create_node(data);
    if (NULL == new_node)
    {
        return;
    }

    pthread_mutex_lock(&llist->mlock);

    if (NULL == llist->head)
    {
        llist->head = new_node;
    }
    else
    {
        llist->tail->next = new_node;
    }
    llist->tail = new_node;
    llist->count++;

    pthread_mutex_unlock(&llist->mlock);
} /* llist_enqueue() */

void *
llist_dequeue(llist_t *llist)
{
    return llist_remove_front(llist);
} /* llist_dequeue() */

void *
llist_peek(llist_t *llist)
{
    if ((NULL == llist) || (NULL == llist->head))
    {
        return NULL;
    }

    return llist->head->data;
} /* llist_peek() */

void *
llist_peek_tail(llist_t *llist)
{
    if ((NULL == llist) || (NULL == llist->tail))
    {
        return NULL;
    }
    return llist->tail->data;

} /* llist_peek_tail() */

void
llist_display(llist_t *llist)
{
    if ((NULL == llist) || (NULL == llist->head))
    {
        return;
    }

    llist_node_t *current = llist->head;

    while (current)
    {
        llist->print(current->data);
        current = current->next;
    }
} /* llist_display() */

/* Creates a new node for a linked list and initializes its data */
static llist_node_t *
create_node(void *data)
{
    llist_node_t *node = NULL;

    if (NULL == data)
    {
        goto EXIT_CREATE_NODE;
    }

    node = calloc(1, sizeof(*node));
    if (node)
    {
        node->data = data;
    }

EXIT_CREATE_NODE:
    return node;
}

/*** end of file ***/
