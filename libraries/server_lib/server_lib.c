#include <errno.h>
#include <stdio.h>

#include "server_lib.h"

#define FAILED  -1
#define SUCCESS 0
#define TCP     0
#define UDP     1

static bool
establish_server_socket(server_t *p_server_info)
{
    bool ret_val = false;

    uint8_t server_type   = p_server_info->server_type;
    int     server_socket = 0;

    if (TCP == server_type)
    {
        server_socket = socket(AF_INET6, SOCK_STREAM, 0);
        if (FAILED == server_socket)
        {
            perror("server socket");
            errno = 0;
            goto EXIT_SERVER_FUNC;
        }

        p_server_info->server_socket = server_socket;
        ret_val                      = true;
    }

    else if (UDP == server_type)
    {
        server_socket = socket(AF_INET6, SOCK_DGRAM, 0);
        if (FAILED == server_socket)
        {
            perror("server socket");
            errno = 0;
            goto EXIT_SERVER_FUNC;
        }

        p_server_info->server_socket = server_socket;
        ret_val                      = true;
    }

EXIT_SERVER_FUNC:
    return ret_val;
}

static bool
set_socket_options(server_t *p_server_info)
{
    bool set_opts = false;

    int server_socket = p_server_info->server_socket;

    // NOTE: &(int){1} creates anonymous temp int variable with value 1
    if (SUCCESS > setsockopt(
            server_socket, SOL_SOCKET, SO_REUSEADDR, &(int) { 1 }, sizeof(int)))
    {
        perror("setsockopt error\n");
        errno = 0;
        goto EXIT_SOCK_OPTS;
    }

    set_opts = true;

EXIT_SOCK_OPTS:

    return set_opts;
}

static bool
set_socket_timeout(server_t *p_server_info)
{
    bool timeout_ret_val = false;

    struct timeval p_serv_sock_timeout = { '\0' };
    p_serv_sock_timeout.tv_sec         = p_server_info->socket_timeout;

    if (SUCCESS > setsockopt(p_server_info->server_socket,
                             SOL_SOCKET,
                             SO_RCVTIMEO,
                             &p_serv_sock_timeout,
                             sizeof(p_serv_sock_timeout)))
    {
        perror("server etsockopt error");
        errno = 0;
        goto EXIT_TIMEOUT;
    }

    timeout_ret_val = true;

EXIT_TIMEOUT:
    return timeout_ret_val;
}

static bool
server_bind_and_listen(server_t *p_server_info)
{
    bool ret_val = false;

    p_server_info->p_server_addr.sin6_family = AF_INET6;
    p_server_info->p_server_addr.sin6_port = htons(p_server_info->port_number);
    p_server_info->p_server_addr.sin6_addr = in6addr_any;

    // NOTE: Cast - Associates server socket with specified address & port
    if (FAILED
        == bind(p_server_info->server_socket,
                (struct sockaddr *)&p_server_info->p_server_addr,
                sizeof(p_server_info->p_server_addr)))
    {
        perror("bind error\n");
        errno = 0;
        goto EXIT_BIND_AND_LISTEN;
    }

    if (FAILED
        == listen(p_server_info->server_socket, p_server_info->max_clients))
    {
        perror("Listen TCP error");
        errno = 0;
        goto EXIT_BIND_AND_LISTEN;
    }

    ret_val = true;

EXIT_BIND_AND_LISTEN:
    return ret_val;
}

bool
establish_server(server_t *p_server_info)
{
    bool ret_val = false;

    if (NULL == p_server_info)
    {
        goto EXIT_SERVER_FUNC;
    }

    bool setup_server_socket = establish_server_socket(p_server_info);
    if (false == setup_server_socket)
    {
        goto EXIT_SERVER_FUNC;
    }

    bool setup_sock_opts = set_socket_options(p_server_info);
    if (false == setup_sock_opts)
    {
        goto EXIT_SERVER_FUNC;
    }

    bool set_timeout = set_socket_timeout(p_server_info);
    if (false == set_timeout)
    {
        goto EXIT_SERVER_FUNC;
    }

    bool bind_and_listen = server_bind_and_listen(p_server_info);
    if (false == bind_and_listen)
    {
        goto EXIT_SERVER_FUNC;
    }

    ret_val = true;

EXIT_SERVER_FUNC:
    return ret_val;
}
