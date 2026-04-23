using ZMQ
include("example.jl")

ctx = ZMQ.context()

# This device executes tasks:
# T1 - T0
# T3 - T1
# T6 - T2, T3
# T8 - T5, T6, T7

# This device participates in communications:
# From:
# D1 -> D0: Transport3
# D1 -> D2: Transport2
# To:
# D0 -> D1: Transport4, Transport5
# D2 -> D1: Transport0, Transport6

# bind sockets that send
@info "binding sockets"

D1D0_pair_socket = Socket(ctx, PAIR)
bind(D1D0_pair_socket, socket_prefix * "_d1d0.socket")

D1D2_pair_socket = Socket(ctx, PAIR)
bind(D1D2_pair_socket, socket_prefix * "_d1d2.socket")

# connect to sockets that recv
@info "connecting sockets"

D0D1_pair_socket = Socket(ctx, PAIR)
connect(D0D1_pair_socket, socket_prefix * "_d0d1.socket")

D2D1_pair_socket = Socket(ctx, PAIR)
connect(D2D1_pair_socket, socket_prefix * "_d2d1.socket")

@info "starting calc"
# do the calculating ™
begin
    T0_data = String(recv(D2D1_pair_socket))
    @info "received $T0_data (expect T0_data)"

    T1_data = compute(T1(), T0_data)
    send(D1D0_pair_socket, T1_data)
    send(D1D2_pair_socket, T1_data)
    @info "sent $T1_data (expect T1_data)"

    T3_data = compute(T3(), T1_data)
    @info "calculated $T3_data (expect T3_data)"

    T2_data = String(recv(D0D1_pair_socket))
    @info "received $T2_data (expect T2_data)"

    T6_data = compute(T6(), T2_data, T3_data)
    @info "calculated $T6_data (expect T6_data)"

    T5_data = String(recv(D0D1_pair_socket))
    @info "received $T5_data (expect T5_data)"

    T7_data = String(recv(D2D1_pair_socket))
    @info "received $T7_data (expect T7_data)"

    T8_data = compute(T8(), T5_data, T6_data, T7_data)
    @info "calculated $T8_data (expect T8_data)"

    @info "D1 finished"
end

@info "closing bound sockets"
close(D1D0_pair_socket)
close(D1D2_pair_socket)
