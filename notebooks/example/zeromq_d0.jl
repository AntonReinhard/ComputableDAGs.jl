using ZMQ
include("example.jl")

ctx = ZMQ.context()

# This device executes tasks:
# T2 - T1, T0
# T5 - T2

# This device participates in communications:
# From:
# D0 -> D1: Transport4, Transport5
# D0 -> D2: Ø
# To:
# D1 -> D0: Transport3
# D2 -> D0: Transport1

# bind sockets that send
@info "binding sockets"

D0D1_pair_socket = Socket(ctx, PAIR)
bind(D0D1_pair_socket, socket_prefix * "_d0d1.socket")

# unused
#D0D2_pair_socket = Socket(ctx, PAIR)
#bind(D0D2_pair_socket, socket_prefix * "_d0d2.socket")

# connect to sockets that recv
@info "connecting sockets"

D1D0_pair_socket = Socket(ctx, PAIR)
connect(D1D0_pair_socket, socket_prefix * "_d1d0.socket")

D2D0_pair_socket = Socket(ctx, PAIR)
connect(D2D0_pair_socket, socket_prefix * "_d2d0.socket")

@info "starting calc"
# do the calculating ™
begin
    T0_data = String(recv(D2D0_pair_socket))
    @info "received $T0_data (expect T0_data)"

    T1_data = String(recv(D1D0_pair_socket))
    @info "received $T1_data (expect T1_data)"

    T2_data = compute(T2(), T1_data, T0_data)
    send(D0D1_pair_socket, T2_data)
    @info "sent $T2_data (expect T2_data)"

    T5_data = compute(T5(), T2_data)
    send(D0D1_pair_socket, T5_data)
    @info "sent $T5_data (expect T5_data)"

    @info "D0 finished"
end

@info "closing bound sockets"
close(D0D1_pair_socket)
