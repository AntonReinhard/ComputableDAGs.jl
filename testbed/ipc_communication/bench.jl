using CSV
using DataFrames
using JLD2

df = DataFrame(socket_type = String[], N = Int[], D0_times = Float64[], D1_times = Float64[], D2_times = Float64[])

for socket_type in ["tcp", "ipc"], N in [round(Int, 2^n) for n in 0.5:0.5:20]
    d0_command = `julia example.jl -q -n $N -d 0 -s $socket_type`
    d1_command = `julia example.jl -q -n $N -d 1 -s $socket_type`
    d2_command = `julia example.jl -q -n $N -d 2 -s $socket_type`

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

    @info "Got times $d0_time/$d1_time/$d2_time for N=$N and socket_type $socket_type"

    push!(
        df, Dict(
            :socket_type => socket_type,
            :N => N,
            :D0_times => d0_time,
            :D1_times => d1_time,
            :D2_times => d2_time,
        )
    )
end

@info "Writing to file"
df |> CSV.write("data/bench.csv")
@save "data/bench.jld2" df
