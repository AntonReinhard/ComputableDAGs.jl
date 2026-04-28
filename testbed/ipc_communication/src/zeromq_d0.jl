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

function run_device(::Val{0}, ::Val{TEST}) where {TEST}
    T0_data = recv(D2D0_socket)
    TEST && @assert T0_data == DATA[1]

    T1_data = recv(D1D0_socket)
    TEST && @assert T1_data == DATA[2]

    T2_data = compute(T2(), T1_data, T0_data)
    send(D0D1_socket, T2_data)
    TEST && @assert T2_data == DATA[3]

    T5_data = compute(T5(), T2_data)
    send(D0D1_socket, T5_data)
    TEST && @assert T5_data == DATA[6]

    return nothing
end
