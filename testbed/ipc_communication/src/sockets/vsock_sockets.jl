# VSOCK is unsupported in ZMQ.jl it seems

@info "setting up VSOCK sockets"

# use VSOCK sockets
socket_prefix = "vsock://*:"

global close_sockets

if DEV == :D0
    D0D1_socket = Socket(ctx, PAIR)
    bind(D0D1_socket, socket_prefix * "5001")

    D0D2_socket = Socket(ctx, PAIR)
    bind(D0D2_socket, socket_prefix * "5002")

    close_sockets = () -> begin
        close(D0D1_socket)
        close(D0D2_socket)
    end
end

if DEV == :D1
    D0D1_socket = Socket(ctx, PAIR)
    connect(D0D1_socket, socket_prefix * "5001")

    D2D1_socket = Socket(ctx, PAIR)
    bind(D2D1_socket, socket_prefix * "5003")

    close_sockets = () -> begin
        close(D0D1_socket)
        close(D2D1_socket)
    end
end

if DEV == :D2
    D0D2_socket = Socket(ctx, PAIR)
    connect(D0D2_socket, socket_prefix * "5002")

    D1D2_socket = Socket(ctx, PAIR)
    connect(D1D2_socket, socket_prefix * "5003")

    close_sockets = () -> begin
        close(D0D2_socket)
        close(D1D2_socket)
    end
end
