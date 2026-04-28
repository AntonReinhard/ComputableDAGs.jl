using CairoMakie
using JLD2
using DataFrames

@load "data/bench.jld2"

colors = Makie.wong_colors()

data = df

f = Figure()
ax = Axis(
    f[1, 1];
    xlabel = "number of runs",
    ylabel = "time taken",
    yminorgridvisible = true,
    yminorticksvisible = true,
    xscale = log10,
    yscale = log10
)

elements = []
labels = []

for (socket_type, color) in [("tcp", 1), ("ipc", 2)]
    relevant_data = df[(df.socket_type .== Ref(socket_type)), :]
    xdata = relevant_data.N
    y0data = relevant_data.D0_times
    y1data = relevant_data.D1_times
    y2data = relevant_data.D2_times

    p = plot!(ax, xdata, y0data; color = colors[color], markersize = 10)
    plot!(ax, xdata, y1data; color = colors[color], markersize = 10)
    plot!(ax, xdata, y2data; color = colors[color], markersize = 10)

    push!(elements, p)
    push!(labels, "Socket type \'$socket_type\'")
end

Legend(f[1, 1], elements, labels; tellheight = false, tellwidth = false, halign = :left, valign = :top)

save("plots/plot.pdf", f)
