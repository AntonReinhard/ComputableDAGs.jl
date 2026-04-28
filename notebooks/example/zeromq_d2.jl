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

function run_device(::Val{2}, ::Val{TEST}) where {TEST}
    T0_data = compute(T0())
    send(D2D0_socket, T0_data)
    send(D2D1_socket, T0_data)
    TEST && @assert T0_data == "T0_data"

    T1_data = String(recv(D1D2_socket))
    TEST && @assert T1_data == "T1_data"

    T4_data = compute(T4(), T1_data)
    TEST && @assert T4_data == "T4_data"

    T7_data = compute(T7(), T4_data)
    send(D2D1_socket, T7_data)
    TEST && @assert T7_data == "T7_data"

    return nothing
end
