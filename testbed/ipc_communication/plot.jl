using CairoMakie
using JLD2
using DataFrames
using Statistics

yticks_t = (
    [1e-4, 2e-4, 5e-4, 1e-3, 2e-3, 5e-3, 1e-2, 2e-2, 5e-2, 1e-1, 2e-1, 5e-1, 1.0],
    ["100 μs", "200 μs", "500 μs", "1 ms", "2 ms", "5 ms", "10 ms", "20 ms", "50 ms", "100 ms", "200 ms", "500 ms", "1 s"]
)
yticks_b = (
    [1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10],
    ["1 kB/s", "10 kB/s", "100 kB/s", "1 MB/s", "10 MB/s", "100 MB/s", "1 GB/s", "10 GB/s"]
)

# loads "df" DataFrame
@load "data/bench_26_05_07.jld2"

colors = Makie.wong_colors()

RUNS = length(Set(df.RUN))

# get medians of the runs
df = groupby(df, [:socket_type, :N, :data_size])
df = combine(
    df,
    :D0_times => median => :D0_times,
    :D1_times => median => :D1_times,
    :D2_times => median => :D2_times,
    :D0_times => std => :D0_std,
    :D1_times => std => :D1_std,
    :D2_times => std => :D2_std,
)

# use set to deduplicate
for data_size in Set(df.data_size)
    @info "Plotting data size $data_size"
    f = Figure(;)
    ax = Axis(
        f[1, 1];
        xlabel="number of runs (#)",
        ylabel="time taken",
        yminorgridvisible=false,
        yminorticksvisible=false,
        xscale=log10,
        yscale=log10,
        xticks=[2^n for n in 0:10],
        yticks=yticks_t,
        title="Test graph communication, sent data packet size = $data_size B, 7 transfers"
    )

    data = df[(df.data_size.==data_size), :]

    elements = []
    labels = []

    for (socket_type, color) in [("tcp", 1), ("ipc", 2)]
        relevant_data = data[(data.socket_type.==Ref(socket_type)), :]

        xdata = relevant_data.N

        y0data = relevant_data.D0_times
        y1data = relevant_data.D1_times
        y2data = relevant_data.D2_times

        y0std = relevant_data.D0_std
        y1std = relevant_data.D1_std
        y2std = relevant_data.D2_std

        p = plot!(ax, xdata, y0data; color=colors[color], markersize=10, marker=:x)
        plot!(ax, xdata, y1data; color=colors[color], markersize=10, marker=:x)
        plot!(ax, xdata, y2data; color=colors[color], markersize=10, marker=:x)

        #= doesn't work with log y axis
        errorbars!(ax, xdata, y0data, y0std; color=colors[color], whiskerwidth=7)
        errorbars!(ax, xdata, y1data, y1std; color=colors[color], whiskerwidth=7)
        errorbars!(ax, xdata, y2data, y2std; color=colors[color], whiskerwidth=7)=#

        push!(elements, p)
        push!(labels, "Socket type \'$socket_type\'")
    end

    Legend(f[1, 1], elements, labels; tellheight=false, tellwidth=false, halign=:left, valign=:top)

    save("plots/26_05_07/communication_bench_$(data_size)B_time.pdf", f)

    f = Figure(;)
    ax = Axis(
        f[1, 1];
        xlabel="number of runs (#)",
        ylabel="data transfer rate (B/s)",
        yminorgridvisible=false,
        yminorticksvisible=false,
        xscale=log10,
        #yscale=log10,
        xticks=[2^n for n in 0:10],
        #yticks=yticks_b,
        title="Test graph communication, sent data packet size = $data_size B, 7 transfers"
    )

    data = df[(df.data_size.==data_size), :]

    elements = []
    labels = []

    for (socket_type, color) in [("tcp", 1), ("ipc", 2)]
        relevant_data = data[(data.socket_type.==Ref(socket_type)), :]

        xdata = relevant_data.N

        # total of 7 IPC transports of size data_size each
        y0data = data_size ./ relevant_data.D0_times .* 7 .* xdata
        y1data = data_size ./ relevant_data.D1_times .* 7 .* xdata
        y2data = data_size ./ relevant_data.D2_times .* 7 .* xdata

        p = plot!(ax, xdata, y0data; color=colors[color], markersize=10, marker=:x)
        plot!(ax, xdata, y1data; color=colors[color], markersize=10, marker=:x)
        plot!(ax, xdata, y2data; color=colors[color], markersize=10, marker=:x)

        #=errorbars!(ax, xdata, y0data, y0std; color=colors[color], whiskerwidth=7)
        errorbars!(ax, xdata, y1data, y1std; color=colors[color], whiskerwidth=7)
        errorbars!(ax, xdata, y2data, y2std; color=colors[color], whiskerwidth=7)=#

        push!(elements, p)
        push!(labels, "Socket type \'$socket_type\'")
    end

    Legend(f[1, 1], elements, labels; tellheight=false, tellwidth=false, halign=:left, valign=:top)

    save("plots/26_05_07/communication_bench_$(data_size)B_datarate.pdf", f)


end
