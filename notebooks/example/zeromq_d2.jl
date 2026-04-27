using ZMQ
include("example.jl")

const DEV = :D2

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

# setup sockets
include("sockets/" * socket_type * "_sockets.jl")

function f(::Val{N}) where {N}
    T0_data = compute(T0())
    send(D2D0_socket, T0_data)
    send(D2D1_socket, T0_data)
    N && @assert T0_data == "T0_data"

    T1_data = String(recv(D1D2_socket))
    N && @assert T1_data == "T1_data"

    T4_data = compute(T4(), T1_data)
    N && @assert T4_data == "T4_data"

    T7_data = compute(T7(), T4_data)
    send(D2D1_socket, T7_data)
    return N && @assert T7_data == "T7_data"
end

@info "starting calc"
f(Val(true))
@info "D2 test finished"

@time for _ in 1:N
    f(Val(false))
end

@info "closing bound sockets"
close_sockets()
