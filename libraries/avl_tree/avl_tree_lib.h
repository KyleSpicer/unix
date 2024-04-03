/**
 * @file avl_tree_lib.h
 * @author CW2 Kyle Spicer
 *
 * @brief The avl_tree.h header file defines the
 * interface for an AVL (Adelson-Velsky and Landis) tree
 * library, providing a set of functions to create,
 * manage, manipulate, and display AVL trees. AVL trees
 * are balanced binary search trees that ensure efficient
 * search, insertion, and deletion operations with
 * logarithmic time complexity 0(log(n)).
 *
 *  @note  O(log(n)) time complexity for all operations
 * in an AVL tree implies that as the number of elements
 * in the tree increases, the time taken for search,
 * insertion, and deletion operations grows at a
 * relatively slower rate, making AVL trees highly
 * efficient and well-suited for handling large datasets
 * with fast and balanced operations.
 *
 * @cite This AVL Tree Library was built throughout the 170D Warrant Officer
 * Basic Course with inspiration from course material.
 *
 * @version 0.3
 * @date 2023-08-17
 *
 * @copyright Copyright (c) 2023
 *
 */
#ifndef AVL_TREE_LIB_H
#define AVL_TREE_LIB_H

#include <stdbool.h> // for bool
#include <stdio.h>   // for FILE

typedef struct avl_tree avl_tree_t;

typedef int (*cmp)(const void *, const void *);
typedef void (*user_display)(void *data);
typedef void (*user_free)(void *data);
typedef void (*write_node_data_func)(void *, FILE *);
typedef void (*user_provided_func)(void *);

/**
 * @brief function to build shell of avl tree and hold comparison function ptr
 *
 * @param tree
 * @param cmp
 */
avl_tree_t *avl_create(cmp cmp_func, user_free user_destory);

/**
 * @brief frees all allocated nodes and the avl tree itself
 *
 * @param p_root - avl tree
 */
void destroy_avl_tree(avl_tree_t **pp_root);

/**
 * @brief insert new node into tree
 *
 * @param tree - already created avl shell or functional tree
 * @param data - void * data
 */
void avl_insert(avl_tree_t *p_tree, void *data);

/**
 * @brief remove node from avl tree
 *
 * @param p_tree
 * @param data
 * @return true
 * @return false
 */
bool avl_delete_node(avl_tree_t *p_tree, void *data);

/**
 * @brief displays avl tree in an easily digestable way
 * @cite received print function from instructor while in 170D WOBC (2022 -
 * 2023)
 */
void avl_display_full(avl_tree_t *p_tree, user_display print);

/**
 * @brief
 *
 * @param tree
 * @param data
 * @return void*
 */
void *avl_search(avl_tree_t *p_tree, void *data);

/**
 * @brief Calculates and returns the total number of nodes in the AVL tree.
 *
 * @param tree The AVL tree to count nodes in.
 * @return The total number of nodes in the AVL tree.
 */
int avl_total_elements(avl_tree_t *p_tree);

/**
 * @brief Traverses the AVL tree in a depth-first "in-order" manner,
 * applying a user-provided function on each node.
 *
 * @param tree The AVL tree to traverse.
 * @param func The function to apply on each node, taking the node data as an
 * argument.
 */
void avl_inorder(avl_tree_t *p_tree, user_provided_func func);

/**
 * @brief Traverses the AVL tree in a depth-first "pre-order" manner,
 * applying a user-provided function on each node.
 *
 * @param tree The AVL tree to traverse.
 * @param func The function to apply on each node, taking the node data as an
 * argument.
 */
void avl_pre_order(avl_tree_t *p_tree, user_provided_func func);

/**
 * @brief Traverses the AVL tree in a depth-first "post-order" manner,
 * applying a user-provided function on each node.
 *
 * @param tree The AVL tree to traverse.
 * @param func The function to apply on each node, taking the node data as an
 * argument.
 */
void avl_post_order(avl_tree_t *p_tree, user_provided_func func);

/**
 * @brief Performs a level-order traversal on the AVL tree, calling a user
 * provided function on each node.
 *
 * @tree: Pointer to the AVL tree.
 * @func: User-provided function to be called on each node.
 */
void avl_level_order(avl_tree_t *p_tree, user_provided_func func);

/**
 * @brief conducts level-order traversal of avl tree and writes each node to
 * file using custom write_func (provided by user)
 *
 * @param tree
 * @param filename
 * @param write_func
 */
void write_avl_tree_to_file(avl_tree_t          *p_tree,
                            const char          *filename,
                            write_node_data_func write_func);

#endif /* AVL_TREE_LIB_H */

/*** end of file ***/
