using ZMQ
include("example.jl")

ctx = ZMQ.context()

# This device executes tasks:
# T0 - Ø
# T4 - T1
# T7 - T4

# This device participates in communications:
# From:
# D2 -> D0: Transport1
# D2 -> D1: Transport0, Transport6
# To:
# D0 -> D2: Ø
# D1 -> D2: Transport2

# bind sockets that send
@info "binding sockets"

D2D0_pair_socket = Socket(ctx, PAIR)
bind(D2D0_pair_socket, socket_prefix * "_d2d0.socket")

D2D1_pair_socket = Socket(ctx, PAIR)
bind(D2D1_pair_socket, socket_prefix * "_d2d1.socket")

# connect to sockets that recv
@info "connecting sockets"

# unused
#D0D2_pair_socket = Socket(ctx, PAIR)
#connect(D0D2_pair_socket, socket_prefix * "_d0d2.socket")

D1D2_pair_socket = Socket(ctx, PAIR)
connect(D1D2_pair_socket, socket_prefix * "_d1d2.socket")

@info "starting calc"
# do the calculating ™
begin
    T0_data = compute(T0())
    send(D2D0_pair_socket, T0_data)
    send(D2D1_pair_socket, T0_data)
    @info "sent $T0_data (expect T0_data)"

    T1_data = String(recv(D1D2_pair_socket))
    @info "received $T1_data (expect T1_data)"

    T4_data = compute(T4(), T1_data)
    @info "calculated $T4_data (expect T4_data)"

    T7_data = compute(T7(), T4_data)
    send(D2D1_pair_socket, T7_data)
    @info "sent $T7_data (expect T7_data)"

    @info "D2 finished"
end

@info "closing bound sockets"
close(D2D0_pair_socket)
close(D2D1_pair_socket)
