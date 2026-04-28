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

function run_device(::Val{1}, ::Val{TEST}) where {TEST}
    T0_data = String(recv(D2D1_socket))
    TEST && @assert T0_data == "T0_data"

    T1_data = compute(T1(), T0_data)
    send(D1D0_socket, T1_data)
    send(D1D2_socket, T1_data)
    TEST && @assert T1_data == "T1_data"

    T3_data = compute(T3(), T1_data)
    TEST && @assert T3_data == "T3_data"

    T2_data = String(recv(D0D1_socket))
    TEST && @assert T2_data == "T2_data"

    T6_data = compute(T6(), T2_data, T3_data)
    TEST && @assert T6_data == "T6_data"

    T5_data = String(recv(D0D1_socket))
    TEST && @assert T5_data == "T5_data"

    T7_data = String(recv(D2D1_socket))
    TEST && @assert T7_data == "T7_data"

    T8_data = compute(T8(), T5_data, T6_data, T7_data)
    TEST && @assert T8_data == "T8_data"

    return nothing
end
