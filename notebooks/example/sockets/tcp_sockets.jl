@info "setting up TCP sockets"

# use IPC sockets
socket_prefix = "tcp://localhost:"

global close_sockets

if DEV == :D0
    D0D1_socket = Socket(ctx, PAIR)
    bind(D0D1_socket, socket_prefix * "5001")
    # reverse socket is the same for PAIR type
    D1D0_socket = D0D1_socket

    D0D2_socket = Socket(ctx, PAIR)
    bind(D0D2_socket, socket_prefix * "5002")
    # reverse socket is the same for PAIR type
    D2D0_socket = D0D2_socket

    close_sockets = () -> begin
        close(D0D1_socket)
        close(D0D2_socket)
    end
end

if DEV == :D1
    D0D1_socket = Socket(ctx, PAIR)
    connect(D0D1_socket, socket_prefix * "5001")
    # reverse socket is the same for PAIR type
    D1D0_socket = D0D1_socket

    D1D2_socket = Socket(ctx, PAIR)
    bind(D1D2_socket, socket_prefix * "5003")
    # reverse socket is the same for PAIR type
    D2D1_socket = D1D2_socket

    close_sockets = () -> begin
        close(D0D1_socket)
        close(D2D1_socket)
    end
end

if DEV == :D2
    D0D2_socket = Socket(ctx, PAIR)
    connect(D0D2_socket, socket_prefix * "5002")
    # reverse socket is the same for PAIR type
    D2D0_socket = D0D2_socket

    D1D2_socket = Socket(ctx, PAIR)
    connect(D1D2_socket, socket_prefix * "5003")
    # reverse socket is the same for PAIR type
    D2D1_socket = D1D2_socket

    close_sockets = () -> begin
        close(D0D2_socket)
        close(D1D2_socket)
    end
end
