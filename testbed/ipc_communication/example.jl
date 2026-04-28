# Full graph: (task - inputs)
# T8 - T5, T6, T7
# T7 - T4
# T6 - T2, T3
# T5 - T2
# T4 - T1
# T3 - T1
# T2 - T1, T0
# T1 - T0
# T0 - Ø

# Three devices in this example:
# D0: T2, T5
# D1: T1, T3, T6, T8
# D2: T0, T4, T7

# 7 inter device transports:
# Transport 0: D2 -> D1 (T0 - T1)
# Transport 1: D2 -> D0 (T0 - T2)
# Transport 2: D1 -> D2 (T1 - T4)
# Transport 3: D1 -> D0 (T1 - T2)
# Transport 4: D0 -> D1 (T2 - T6)
# Transport 5: D0 -> D1 (T5 - T8)
# Transport 6: D2 -> D1 (T7 - T8)

# this example has the following PAIRs in use:
# D0 -> D1: Transport4, Transport5
# D0 -> D2: Ø
# D1 -> D0: Transport3
# D1 -> D2: Transport2
# D2 -> D0: Transport1
# D2 -> D1: Transport0, Transport6

using ZMQ
using ArgParse

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "-n"
        help = "number of runs"
        arg_type = Int
        required = true
        "--data"
        help = "how much data to transfer with each task (in Bytes)"
        arg_type = Int
        default = 8
        "--device", "-d"
        help = "which device to start (0-2)"
        arg_type = Int
        required = true
        "--socket", "-s"
        help = "socket type to use (tcp/ipc)"
        arg_type = String
        required = true
        "--quiet", "-q"
        help = "no output other than time taken"
        action = :store_true
    end

    return parse_args(s)
end

global DEV::Symbol

global D0D1_socket
global D0D2_socket
global D1D0_socket
global D1D2_socket
global D2D0_socket
global D2D1_socket

include("src/tasks.jl")

include("src/sockets/tcp_sockets.jl")
include("src/sockets/ipc_sockets.jl")

include("src/zeromq_d0.jl")
include("src/zeromq_d1.jl")
include("src/zeromq_d2.jl")

function main()
    parsed_args = parse_commandline()

    dev = parsed_args["device"]
    N = parsed_args["n"]
    socket_type = parsed_args["socket"]
    Q = parsed_args["quiet"]
    D = parsed_args["data"]

    v_socket = Val(Symbol(socket_type))
    v_dev = Val(dev)

    Q || @info "Running $N runs with device $dev and socket type $socket_type and $D bytes of data per message"

    ctx = ZMQ.context()
    global DEV = Symbol("D" * string(dev))

    Q || @info "Setting up"

    open_sockets(v_dev, v_socket, ctx)
    setup_tasks(D)

    Q || @info "Starting test"
    run_device(v_dev, Val(true))
    run_device(v_dev, Val(false))
    GC.gc()

    Q || @info "Device " * string(dev) * " test finished"

    elapsed = @elapsed for _ in 1:N
        run_device(v_dev, Val(false))
        # i hate julia sometimes
        # GC.gc()
    end

    println(elapsed)

    Q || @info "Closing bound sockets"
    return close_sockets(v_dev, v_socket)
end

main()
