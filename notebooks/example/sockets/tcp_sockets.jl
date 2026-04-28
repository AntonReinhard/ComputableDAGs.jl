function open_sockets(::Val{0}, ::Val{:tcp}, ctx)
    socket_prefix = "tcp://localhost:"

    global D0D1_socket = Socket(ctx, PAIR)
    bind(D0D1_socket, socket_prefix * "5001")
    # reverse socket is the same for PAIR type
    global D1D0_socket = D0D1_socket

    global D0D2_socket = Socket(ctx, PAIR)
    bind(D0D2_socket, socket_prefix * "5002")
    # reverse socket is the same for PAIR type
    return global D2D0_socket = D0D2_socket
end

function close_sockets(::Val{0}, ::Val{:tcp})
    close(D0D1_socket)
    return close(D0D2_socket)
end

function open_sockets(::Val{1}, ::Val{:tcp}, ctx)
    socket_prefix = "tcp://localhost:"

    global D0D1_socket = Socket(ctx, PAIR)
    connect(D0D1_socket, socket_prefix * "5001")
    # reverse socket is the same for PAIR type
    global D1D0_socket = D0D1_socket

    global D1D2_socket = Socket(ctx, PAIR)
    bind(D1D2_socket, socket_prefix * "5003")
    # reverse socket is the same for PAIR type
    return global D2D1_socket = D1D2_socket
end

function close_sockets(::Val{1}, ::Val{:tcp})
    close(D0D1_socket)
    return close(D2D1_socket)
end

function open_sockets(::Val{2}, ::Val{:tcp}, ctx)
    socket_prefix = "tcp://localhost:"

    global D0D2_socket = Socket(ctx, PAIR)
    connect(D0D2_socket, socket_prefix * "5002")
    # reverse socket is the same for PAIR type
    global D2D0_socket = D0D2_socket

    global D1D2_socket = Socket(ctx, PAIR)
    connect(D1D2_socket, socket_prefix * "5003")
    # reverse socket is the same for PAIR type
    return global D2D1_socket = D1D2_socket
end

function close_sockets(::Val{2}, ::Val{:tcp})
    close(D0D2_socket)
    return close(D1D2_socket)
end
