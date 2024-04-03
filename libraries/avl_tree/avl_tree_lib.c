/**
 * @file avl_tree_lib.c
 * @author CW2 Kyle Spicer
 *
 * @brief The avl_tree.c file contains an implementation
 * of an AVL (Adelson-Velsky and Landis) tree, a self
 * balancing binary search tree. The AVL tree maintains
 * balance by ensuring that the height difference between
 * its left and right subtrees (also known as the balance
 * factor) is always at most one.
 *
 * @version 0.4
 * @date 2023-08-17
 *
 * @cite Logic for this library was inspired/adapted from
 * the coursework
 * provided during the 170D Warrant Officer Basic Course
 * (2022 - 2023). US Army Cyber School.
 *
 * @cite Logic for printing the avl tree was inspired and
 * adapted from:
 * www.techiedelight.com/c-program-print-binary-tree/.
 */

#include <errno.h>   // for errno
#include <pthread.h> // for pthread_mutex_lock, pthread_mutex_u...
#include <stdbool.h> // for bool
#include <stdlib.h>  // for calloc, free

#include "include/avl_tree_lib.h"

typedef struct avl_node_t avl_node_t;

struct avl_node_t
{
    void       *data;
    int         height;
    avl_node_t *p_left;
    avl_node_t *p_right;
};

struct avl_tree
{
    avl_node_t *p_root;
    int         count;
    int (*cmp)(const void *, const void *);
    void (*user_display)(void *data);
    void (*user_free)(void *data);
    pthread_mutex_t p_tree_lock;
};

typedef struct q_node
{
    avl_node_t    *p_data;
    struct q_node *p_next;
} q_node_t;

typedef struct queue
{
    q_node_t *p_head;
    q_node_t *p_tail;
} queue_t;

/**
 * @brief recursively destroys avl tree nodes with provided user_destroy
 * function.
 *
 * @param p_node: node to destroy
 * @param user_destroy: user provided destroy function
 */
static void destroy_avl_node(avl_node_t *p_node, user_free user_destroy);

/**
 * @brief returns the larger of the two inputs
 *
 * @param a: first integer
 * @param b: second integer
 * @return int
 */
static int max(int a, int b);

/**
 * @brief return the height of the input node
 *
 * @param node
 * @return int
 */
static int height(avl_node_t *p_node);

/**
 * @brief conducts a proper rotate p_right to keep tree balanced
 *
 * @param node
 * @return avl_node_t*
 */
static avl_node_t *rotate_p_right(avl_node_t *p_node);

/**
 * @brief conducts a proper rotate p_left to keep tree balanced
 *
 * @param node
 * @return avl_node_t*
 */
static avl_node_t *rotate_p_left(avl_node_t *p_node);

/**
 * @brief conducts a proper rotate p_left, p_right to keep tree balanced
 *
 * @param node
 * @return avl_node_t*
 */
static avl_node_t *rotate_p_left_p_right(avl_node_t *p_node);

/**
 * @brief conducts a proper rotate p_right, p_left to keep tree balanced
 *
 * @param node
 * @return avl_node_t*
 */
static avl_node_t *rotate_p_right_p_left(avl_node_t *p_node);

/**
 * @brief inserts node into avl tree
 *
 * @param node
 * @param data
 * @param cmp
 * @return avl_node_t*
 */
static avl_node_t *insert_node(avl_node_t *p_node, void *data, cmp cmp_func);

/**
 * @brief Recursive helper function to search for a node in AVL tree.
 *
 * @param p_root
 * @param data
 * @param cmp_func
 * @return void*
 */
static void *search_helper(avl_node_t *p_root, void *data, cmp cmp_func);

/**
 * @brief Recursive helper function that counts nodes.
 *
 * @param p_node
 * @return int
 */
static int avl_node_count(avl_node_t *p_node);

/**
 * @brief Perform in-order traversal on AVL Tree
 *
 * @param p_root
 * @param user_func
 */
static void avl_inorder_action(avl_node_t        *p_root,
                               user_provided_func user_func);
/**
 * @brief Perform pre-order traversal on AVL Tree
 *
 * @param p_root
 * @param user_func
 */
static void avl_pre_order_action(avl_node_t        *p_root,
                                 user_provided_func user_func);
/**
 * @brief Perform post-order traversal on AVL tree
 *
 * @param p_root
 * @param user_func
 */
static void avl_post_order_action(avl_node_t        *p_root,
                                  user_provided_func user_func);
/**
 * @brief create queue for avl level order traversal
 *
 * @return queue_t*
 */
static queue_t *queue_create(void);

/**
 * @brief Enqueues a data element into AVL level order queue.
 *
 * @param p_queue
 * @param p_data
 */
static void enqueue(queue_t *p_queue, avl_node_t *p_data);

/**
 * @brief Dequeues a data element from AVL level order queue.
 *
 * @param p_queue
 * @return avl_node_t*
 */
static avl_node_t *dequeue(queue_t *p_queue);

/**
 * @brief returns true/false if node is present in the queue
 *
 * @param p_queue
 * @return true: if queue->head exists
 * @return false: if if queue->head == NULL
 */
static bool queue_is_empty(queue_t *p_queue);

/**
 * @brief Destroys avl level order queue and frees allocated memory
 *
 * @param p_queue
 */
static void queue_destroy(queue_t *p_queue);

avl_tree_t *
avl_create(cmp cmp_func, user_free user_destory)
{
    avl_tree_t *p_new_tree = NULL;

    if ((NULL == cmp_func) || (NULL == user_destory))
    {
        goto EXIT_AVL_CREATE;
    }

    p_new_tree = calloc(1, sizeof(avl_tree_t));
    if (NULL == p_new_tree)
    {
        perror("avl tree create calloc");
        goto EXIT_AVL_CREATE;
    }

    p_new_tree->cmp       = cmp_func;
    p_new_tree->user_free = user_destory;
    pthread_mutex_init(&(p_new_tree->p_tree_lock), NULL);

EXIT_AVL_CREATE:
    return p_new_tree;
} /* avl_create() */

/**
 * @brief helper function to delete specified node from avl tree while keeping
 * balance.
 *
 * @param pp_root
 * @param data
 * @param cmp_func
 * @param destroy
 * @return true
 * @return false
 */
static bool delete_node(avl_node_t **pp_root,
                        void        *data,
                        cmp          cmp_func,
                        user_free    destroy);

void
destroy_avl_tree(avl_tree_t **pp_root)
{
    if ((NULL == pp_root) || (NULL == *pp_root))
    {
        return;
    }

    pthread_mutex_lock(&(*pp_root)->p_tree_lock);

    destroy_avl_node((*pp_root)->p_root, (*pp_root)->user_free);

    pthread_mutex_unlock(&(*pp_root)->p_tree_lock);
    pthread_mutex_destroy(&(*pp_root)->p_tree_lock);

    free(*pp_root);
    *pp_root = NULL;
} /* destroy_avl_tree */

void
avl_insert(avl_tree_t *p_tree, void *data)
{
    if ((NULL == p_tree) || (NULL == data))
    {
        return;
    }

    pthread_mutex_lock(&(p_tree->p_tree_lock));

    p_tree->p_root = insert_node(p_tree->p_root, data, p_tree->cmp);
    p_tree->count++;

    pthread_mutex_unlock(&(p_tree->p_tree_lock));

} /* avl_insert() */

bool
avl_delete_node(avl_tree_t *p_tree, void *data)
{
    bool b_was_delete_success = false;
    if (NULL == p_tree || NULL == data)
    {
        goto EXIT_AVL_DELETE_NODE;
    }

    pthread_mutex_lock(&(p_tree->p_tree_lock));
    b_was_delete_success
        = delete_node(&(p_tree->p_root), data, p_tree->cmp, p_tree->user_free);
    if (true == b_was_delete_success)
    {
        p_tree->count--;
    }
    pthread_mutex_unlock(&(p_tree->p_tree_lock));
EXIT_AVL_DELETE_NODE:
    return b_was_delete_success;
}

struct trunk
{
    struct trunk *p_prev;
    const char   *str;
};

static void
print_trunks(struct trunk *p)
{
    if (NULL == p)
    {
        return;
    }

    print_trunks(p->p_prev);
    printf("%s", p->str);
} /* print_trunks() */

static void
print_recursive(avl_node_t   *p_root,
                struct trunk *p_prev,
                int           is_p_left,
                user_display  user_print)
{
    if (NULL == p_root)
    {
        return;
    }

    struct trunk this_disp  = { p_prev, "     " };
    const char  *p_prev_str = this_disp.str;
    print_recursive(p_root->p_right, &this_disp, 1, user_print);

    if (NULL == p_prev)
    {
        this_disp.str = "---";
    }

    else if (is_p_left)
    {
        this_disp.str = ".--";
        p_prev_str    = "    |";
    }

    else
    {
        this_disp.str = "`--";
        p_prev->str   = p_prev_str;
    }

    print_trunks(&this_disp);
    user_print(p_root->data);

    if (p_prev)
    {
        p_prev->str = p_prev_str;
    }
    this_disp.str = "    |";

    print_recursive(p_root->p_left, &this_disp, 0, user_print);

    if (NULL == p_prev)
    {
        puts("");
    }
} /* print_recursive() */

void
avl_display_full(avl_tree_t *p_tree, user_display print)
{
    if (NULL == p_tree->p_root || NULL == print)
    {
        return;
    }
    pthread_mutex_lock(&(p_tree->p_tree_lock));

    print_recursive(p_tree->p_root, NULL, 0, print);

    pthread_mutex_unlock(&(p_tree->p_tree_lock));

} /* avl_display_full() */

void *
avl_search(avl_tree_t *p_tree, void *data)
{
    void *result = NULL;

    if (NULL == p_tree || NULL == data)
    {
        goto EXIT_AVL_SEARCH;
    }

    pthread_mutex_lock(&(p_tree->p_tree_lock));

    result = search_helper(p_tree->p_root, data, p_tree->cmp);

    pthread_mutex_unlock(&(p_tree->p_tree_lock));

EXIT_AVL_SEARCH:
    return result;

} /* avl_search() */

int
avl_total_elements(avl_tree_t *p_tree)
{
    int ret_count = 0;

    if (NULL == p_tree)
    {
        goto EXIT_TOTAL_ELEMENTS;
    }

    pthread_mutex_lock(&(p_tree->p_tree_lock));

    // Call the helper function on the p_root of the tree.
    ret_count = avl_node_count(p_tree->p_root);

    pthread_mutex_unlock(&(p_tree->p_tree_lock));

EXIT_TOTAL_ELEMENTS:
    return ret_count;
} /* avl_total_elements() */

void
avl_inorder(avl_tree_t *p_tree, user_provided_func user_func)
{
    if ((NULL == p_tree) || (NULL == user_func))
    {
        return;
    }

    pthread_mutex_lock(&(p_tree->p_tree_lock));

    avl_inorder_action(p_tree->p_root, user_func);

    pthread_mutex_unlock(&(p_tree->p_tree_lock));
} /* avl_inorder() */

void
avl_pre_order(avl_tree_t *p_tree, user_provided_func user_func)
{
    if ((NULL == p_tree) || (NULL == user_func))
    {
        return;
    }

    pthread_mutex_lock(&(p_tree->p_tree_lock));

    avl_pre_order_action(p_tree->p_root, user_func);
    printf("\n");

    pthread_mutex_unlock(&(p_tree->p_tree_lock));
} /* avl_pre_order() */

void
avl_post_order(avl_tree_t *p_tree, user_provided_func user_func)
{
    if ((NULL == p_tree) || (NULL == user_func))
    {
        return;
    }

    pthread_mutex_lock(&(p_tree->p_tree_lock));

    avl_post_order_action(p_tree->p_root, user_func);
    printf("\n");

    pthread_mutex_unlock(&(p_tree->p_tree_lock));
} /* avl_post_order() */

void
avl_level_order(avl_tree_t *p_tree, user_provided_func func)
{
    if ((NULL == p_tree) || (NULL == p_tree->p_root) || (NULL == func))
    {
        return;
    }

    queue_t *p_queue = queue_create();
    if (NULL == p_queue)
    {
        return;
    }

    enqueue(p_queue, p_tree->p_root);

    while (false == queue_is_empty(p_queue))
    {
        avl_node_t *p_node = dequeue(p_queue);

        func(p_node->data);

        if (p_node->p_left)
        {
            enqueue(p_queue, p_node->p_left);
        }

        if (p_node->p_right)
        {
            enqueue(p_queue, p_node->p_right);
        }
    }

    queue_destroy(p_queue);
} /* avl_level_order() */

void
write_avl_tree_to_file(avl_tree_t          *p_tree,
                       const char          *filename,
                       write_node_data_func write_func)
{
    if ((NULL == p_tree) || (NULL == p_tree->p_root) || (NULL == filename))
    {
        return;
    }
    FILE *h_out_file = fopen(filename, "wb");
    if (!h_out_file)
    {
        perror("fopen out file");
        errno = 0;
        return;
    }

    pthread_mutex_lock(&p_tree->p_tree_lock);

    // create queue for level-order traversal
    queue_t *p_queue = queue_create();
    if (NULL == p_queue)
    {
        fclose(h_out_file);
        pthread_mutex_unlock(&p_tree->p_tree_lock);
        return;
    }

    // enqueue the p_root node
    enqueue(p_queue, p_tree->p_root);

    // perform level-order traversal
    while (false == queue_is_empty(p_queue))
    {
        avl_node_t *p_current = dequeue(p_queue);

        // write node_data_to_file function
        write_func(p_current->data, h_out_file);

        // enqueue p_left child if exists
        if (p_current->p_left)
        {
            enqueue(p_queue, p_current->p_left);
        }

        // enqueue p_right child if exists
        if (p_current->p_right)
        {
            enqueue(p_queue, p_current->p_right);
        }
    }

    pthread_mutex_unlock(&p_tree->p_tree_lock);
    queue_destroy(p_queue);
    fclose(h_out_file);
} /* write_avl_tree_to_file() */

/* recursvely destroy avl node with user destroy function */
static void
destroy_avl_node(avl_node_t *p_node, user_free user_destroy)
{
    if ((NULL == p_node) || (NULL == user_destroy))
    {
        return;
    }

    destroy_avl_node(p_node->p_left, user_destroy);
    destroy_avl_node(p_node->p_right, user_destroy);

    user_destroy(p_node->data);

    free(p_node);
} /* destroy_avl_node() */

// returns larger of two inputs
static int
max(int a, int b)
{
    return (a > b) ? a : b;
} /* max() */

/* return the height of the input node */
static int
height(avl_node_t *p_node)
{
    return (NULL == p_node) ? -1 : p_node->height;
} /* height() */

/* conducts a proper rotate p_right to keep tree balanced */
static avl_node_t *
rotate_p_right(avl_node_t *p_node)
{
    avl_node_t *p_left = NULL;

    if ((NULL == p_node) || (NULL == p_node->p_left))
    {
        goto EXIT_ROT_P_RIGHT;
    }

    p_left          = p_node->p_left;
    p_node->p_left  = p_left->p_right;
    p_left->p_right = p_node;
    p_node->height  = max(height(p_node->p_left), height(p_node->p_right)) + 1;
    p_left->height  = max(height(p_left->p_left), p_node->height) + 1;

EXIT_ROT_P_RIGHT:
    return p_left;

} /* rotate_p_right() */

/* conducts a proper rotate p_left to keep tree balanced */
static avl_node_t *
rotate_p_left(avl_node_t *p_node)
{
    avl_node_t *p_right = NULL;

    if ((NULL == p_node) || (NULL == p_node->p_right))
    {
        goto EXIT_ROT_P_LEFT;
    }

    p_right         = p_node->p_right;
    p_node->p_right = p_right->p_left;
    p_right->p_left = p_node;
    p_node->height  = max(height(p_node->p_left), height(p_node->p_right)) + 1;
    p_right->height = max(height(p_right->p_right), p_node->height) + 1;

EXIT_ROT_P_LEFT:
    return p_right;
} /* rotate_p_left() */

/* conducts proper rotate p_left, p_right to keep tree balanced */
static avl_node_t *
rotate_p_left_p_right(avl_node_t *p_node)
{
    p_node->p_left = rotate_p_left(p_node->p_left);
    return rotate_p_right(p_node);
} /* rotate_p_left_p_right() */

/* conducts proper rotate p_right, p_left to keep tree balanced */
static avl_node_t *
rotate_p_right_p_left(avl_node_t *p_node)
{
    avl_node_t *result = NULL;
    if (NULL == p_node)
    {
        goto EXIT_ROT_RIGHT_LEFT;
    }

    p_node->p_right = rotate_p_right(p_node->p_right);
    result          = rotate_p_left(p_node);

EXIT_ROT_RIGHT_LEFT:
    return result;

} /* rotate_p_right_p_left() */

/* inserts node into avl tree */
static avl_node_t *
insert_node(avl_node_t *p_node, void *data, cmp cmp_func)
{
    if ((NULL == p_node) || (NULL == data) || (NULL == cmp_func))
    {
        avl_node_t *p_new_node = calloc(1, sizeof(avl_node_t));
        if (NULL == p_new_node)
        {
            perror("avl insert node calloc");
            errno = 0;
            return NULL;
        }
        p_new_node->data = data;

        return p_new_node;
    }

    int result = cmp_func(data, p_node->data);

    if (0 > result)
    {
        p_node->p_left = insert_node(p_node->p_left, data, cmp_func);

        if (height(p_node->p_left) - height(p_node->p_right) == 2)
        {
            if (0 > cmp_func(data, p_node->p_left->data))
            {
                p_node = rotate_p_right(p_node);
            }

            else
            {
                p_node = rotate_p_left_p_right(p_node);
            }
        }
    }

    else if (0 < result)
    {
        p_node->p_right = insert_node(p_node->p_right, data, cmp_func);

        if (2 == height(p_node->p_right) - height(p_node->p_left))
        {
            if (0 < cmp_func(data, p_node->p_right->data))
            {
                p_node = rotate_p_left(p_node);
            }

            else
            {
                p_node = rotate_p_right_p_left(p_node);
            }
        }
    }

    p_node->height = max(height(p_node->p_left), height(p_node->p_right)) + 1;

    return p_node;
} /* insert_node() */

/* Recursive helper function to search for a node in AVL tree. */
static void *
search_helper(avl_node_t *p_root, void *data, cmp cmp_func)
{
    if ((NULL == p_root) || (NULL == data) || (NULL == cmp_func))
    {
        return NULL;
    }

    int result = cmp_func(p_root->data, data);

    if (0 == result)
    {
        return p_root->data;
    }

    else if (0 > result)
    {
        return search_helper(p_root->p_right, data, cmp_func);
    }

    else
    {
        return search_helper(p_root->p_left, data, cmp_func);
    }
} /* search_helper() */

/* Recursive helper function that counts nodes. */
static int
avl_node_count(avl_node_t *p_node)
{
    if (NULL == p_node)
    {
        return 0;
    }

    // The node itself counts as one, hence the '+ 1' at the end.
    return avl_node_count(p_node->p_left) + avl_node_count(p_node->p_right) + 1;
} /* avl_node_count() */

/* Perform in-order traversal on AVL Tree */
static void
avl_inorder_action(avl_node_t *p_root, user_provided_func user_func)
{
    if ((NULL == p_root) || (NULL == user_func))
    {
        return;
    }

    avl_inorder_action(p_root->p_left, user_func);
    user_func(p_root->data);
    avl_inorder_action(p_root->p_right, user_func);
} /* avl_inorder_action() */

/* Perform pre-order traversal on AVL Tree */
static void
avl_pre_order_action(avl_node_t *p_root, user_provided_func user_func)
{
    if ((NULL == p_root) || (NULL == user_func))
    {
        return;
    }

    user_func(p_root->data);
    avl_pre_order_action(p_root->p_left, user_func);
    avl_pre_order_action(p_root->p_right, user_func);
} /* avl_pre_order_action() */

/* Perform post-order traversal on AVL tree */
static void
avl_post_order_action(avl_node_t *p_root, user_provided_func user_func)
{
    if ((NULL == p_root) || (NULL == user_func))
    {
        return;
    }

    avl_post_order_action(p_root->p_left, user_func);
    avl_post_order_action(p_root->p_right, user_func);
    user_func(p_root->data);
} /* avl_post_order_action() */

/* create queue for avl level order traversal */
static queue_t *
queue_create(void)
{
    queue_t *p_queue = calloc(1, sizeof(queue_t));
    if (NULL == p_queue)
    {
        perror("avl level order queue create calloc");
        errno = 0;
        return NULL;
    }

    return p_queue;
} /* queue_create() */

/* Enqueues a data element into AVL level order queue. */
static void
enqueue(queue_t *p_queue, avl_node_t *p_data)
{
    if ((NULL == p_queue) || (NULL == p_data))
    {
        return;
    }

    q_node_t *p_new_node = calloc(1, sizeof(q_node_t));
    if (NULL == p_new_node)
    {
        perror("avl new node level order enqueue");
        errno = 0;
        return;
    }

    p_new_node->p_data = p_data;

    if (!p_queue->p_tail)
    {
        p_queue->p_head = p_new_node;
        p_queue->p_tail = p_new_node;
    }

    else
    {
        p_queue->p_tail->p_next = p_new_node;
        p_queue->p_tail         = p_new_node;
    }
} /* enqueue() */

/* Dequeues a data element from AVL level order queue. */
static avl_node_t *
dequeue(queue_t *p_queue)
{
    avl_node_t *p_data = NULL;
    if ((NULL == p_queue) || (NULL == p_queue->p_head))
    {
        goto EXIT_AVL_DEQUEUE;
    }

    q_node_t *p_temp = p_queue->p_head;
    p_data           = p_temp->p_data;

    if (p_queue->p_head == p_queue->p_tail)
    {
        p_queue->p_head = NULL;
        p_queue->p_tail = NULL;
    }

    else
    {
        p_queue->p_head = p_queue->p_head->p_next;
    }

    free(p_temp);

EXIT_AVL_DEQUEUE:
    return p_data;
} /* dequeue() */

/* returns true/false if node is present in the queue */
static bool
queue_is_empty(queue_t *p_queue)
{
    return (NULL == p_queue->p_head);
} /* queue_is_empty() */

/* Destroys avl level order queue and frees allocated memory */
static void
queue_destroy(queue_t *p_queue)
{
    if (NULL == p_queue)
    {
        return;
    }

    while (!queue_is_empty(p_queue))
    {
        dequeue(p_queue);
    }

    free(p_queue);
} /* queue_destroy() */

/* deletes node from avl tree, keeping balance */
static bool
delete_node(avl_node_t **pp_root, void *data, cmp cmp_func, user_free destroy)
{
    bool b_node_deleted = false;

    if ((NULL == pp_root) || (NULL == data) || (NULL == cmp_func))
    {
        goto EXIT_DELETE_NODE;
    }

    if (*pp_root == NULL)
    {
        goto EXIT_DELETE_NODE;
    }

    int result = cmp_func(data, (*pp_root)->data);

    if (0 > result) // NOTE: node to delete is in left subtree
    {
        b_node_deleted
            = delete_node(&((*pp_root)->p_left), data, cmp_func, destroy);
    }

    else if (0 < result) // NOTE: node to be deleted in right subtree
    {
        b_node_deleted
            = delete_node(&((*pp_root)->p_right), data, cmp_func, destroy);
    }

    else // NOTE: node found, delete
    {
        avl_node_t *p_to_delete = *pp_root;

        if (NULL == p_to_delete->p_left)
        {
            *pp_root = p_to_delete->p_right;
            destroy(p_to_delete->data);
            free(p_to_delete);
            b_node_deleted = true;
        }

        else if (NULL == p_to_delete->p_right)
        {
            *pp_root = p_to_delete->p_left;
            destroy(p_to_delete->data);
            free(p_to_delete);
            b_node_deleted = true;
        }

        else // NOTE: node has two children, find in-order successor
        {
            avl_node_t *p_parent_of_successor = p_to_delete;
            avl_node_t *p_successor           = p_to_delete->p_right;

            while (NULL != p_successor->p_left)
            {
                p_parent_of_successor = p_successor;
                p_successor           = p_successor->p_left;
            }

            void *tmp_data    = p_to_delete->data;
            p_to_delete->data = p_successor->data;
            // p_successor->data = tmp_data;

            // NOTE: delete the in-order successor node
            if (p_parent_of_successor->p_right == p_successor)
            {
                p_parent_of_successor->p_right = p_successor->p_right;
            }

            else
            {
                p_parent_of_successor->p_left = p_successor->p_right;
            }
            destroy(tmp_data);
            // destroy(p_successor->data);
            free(p_successor);
            b_node_deleted = true;
        }
    }

    // NOTE: perform rotations, update height
    if (*pp_root)
    {
        (*pp_root)->height
            = 1 + max(height((*pp_root)->p_left), height((*pp_root)->p_right));

        int balance = height((*pp_root)->p_left) - height((*pp_root)->p_right);

        if (1 < balance)
        {
            if (height((*pp_root)->p_left->p_left)
                >= height((*pp_root)->p_left->p_right))
            {
                *pp_root = rotate_p_right(*pp_root);
            }

            else
            {
                (*pp_root)->p_left = rotate_p_left((*pp_root)->p_left);
                *pp_root           = rotate_p_right(*pp_root);
            }
        }

        else if (-1 > balance)
        {
            if (height((*pp_root)->p_right->p_right)
                >= height((*pp_root)->p_right->p_left))
            {
                *pp_root = rotate_p_left(*pp_root);
            }
            else
            {
                (*pp_root)->p_right = rotate_p_right((*pp_root)->p_right);
                *pp_root            = rotate_p_left(*pp_root);
            }
        }
    }

EXIT_DELETE_NODE:
    return b_node_deleted;
} /* delete_node() */

/*** end of file ***/
