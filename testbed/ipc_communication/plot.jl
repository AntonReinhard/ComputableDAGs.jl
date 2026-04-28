using CairoMakie
using JLD2
using DataFrames

# loads "df" DataFrame
@load "data/bench.jld2"

colors = Makie.wong_colors()

# use set to deduplicate
for data_size in Set(df.data_size)
    f = Figure(; title = "Small test graph communication, sent data packet size = $data_size B")
    ax = Axis(
        f[1, 1];
        xlabel = "number of runs (#)",
        ylabel = "time taken (s)",
        yminorgridvisible = true,
        yminorticksvisible = true,
        xscale = log10,
        yscale = log10
    )

    data = df[(df.data_size .== data_size), :]

    elements = []
    labels = []

    for (socket_type, color) in [("tcp", 1), ("ipc", 2)]
        relevant_data = data[(data.socket_type .== Ref(socket_type)), :]
        xdata = relevant_data.N
        y0data = relevant_data.D0_times
        y1data = relevant_data.D1_times
        y2data = relevant_data.D2_times

        ydata = (y0data .+ y1data .+ y2data) ./ 3

        p = plot!(ax, xdata, ydata; color = colors[color], markersize = 10)
        #plot!(ax, xdata, y1data; color=colors[color], markersize=10)
        #plot!(ax, xdata, y2data; color=colors[color], markersize=10)

        push!(elements, p)
        push!(labels, "Socket type \'$socket_type\'")
    end

    Legend(f[1, 1], elements, labels; tellheight = false, tellwidth = false, halign = :left, valign = :top)

    save("plots/communication_bench_$(data_size)B.pdf", f)
end
