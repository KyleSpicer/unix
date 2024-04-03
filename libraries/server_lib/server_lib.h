#ifndef SERVER_LIB
#define SERVER_LIB

#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/time.h>

typedef struct server_t server_t;

struct server_t
{
    uint16_t            port_number;
    uint8_t             server_type; // 0: TCP, 1: UDP
    uint8_t             max_clients;
    struct sockaddr_in6 p_server_addr;
    int                 server_socket;
    int                 client_socket;
    int                 socket_timeout;
};

/**
 * @brief
 *
 * @param
 *
 * @return true:  successfully started server
 * @return false: failed to start server
 */
bool establish_server(server_t *p_server_info);

#endif /* SERVER_LIB */
