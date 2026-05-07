using CSV
using DataFrames
using JLD2

df = DataFrame(socket_type=String[], N=Int[], data_size=Int[], D0_times=Float64[], D1_times=Float64[], D2_times=Float64[], RUN=Int[])

RUNS = Dict(
    1 => 50,
    2 => 50,
    3 => 50,
    4 => 50,
    6 => 25,
    8 => 25,
    11 => 25,
    16 => 10,
    23 => 10,
    32 => 10,
    45 => 10,
    64 => 10,
    91 => 10
)

for SOCKET_TYPE in ["tcp", "ipc"], N in [round(Int, 2^n) for n in 0.5:0.5:10], DATA in [round(Int, 2^n) for n in 0:3:15]
    for RUN in 1:get(RUNS, N, 5)
        d0_command = `julia example.jl -q -n $N -d 0 -s $SOCKET_TYPE --data $DATA`
        d1_command = `julia example.jl -q -n $N -d 1 -s $SOCKET_TYPE --data $DATA`
        d2_command = `julia example.jl -q -n $N -d 2 -s $SOCKET_TYPE --data $DATA`

        io_d0 = PipeBuffer()
        io_d1 = PipeBuffer()
        io_d2 = PipeBuffer()

        t0 = Threads.@spawn run(d0_command, devnull, io_d0, stderr)
        t1 = Threads.@spawn run(d1_command, devnull, io_d1, stderr)
        t2 = Threads.@spawn run(d2_command, devnull, io_d2, stderr)

        Threads.wait(t0)
        Threads.wait(t1)
        Threads.wait(t2)

        d0_time = parse(Float64, readlines(io_d0)[1])
        d1_time = parse(Float64, readlines(io_d1)[1])
        d2_time = parse(Float64, readlines(io_d2)[1])

        @info "Got times $d0_time/$d1_time/$d2_time for N=$N and SOCKET_TYPE $SOCKET_TYPE and $DATA B of data"

        push!(
            df, Dict(
                :socket_type => SOCKET_TYPE,
                :N => N,
                :data_size => DATA,
                :D0_times => d0_time,
                :D1_times => d1_time,
                :D2_times => d2_time,
                :RUN => RUN
            )
        )
    end
end

@info "Writing to file"
df |> CSV.write("data/bench.csv")
@save "data/bench.jld2" df
