# == Total Generation Time as Stacked Bars ==
# graph gen times
result = BenchmarkTools.load(jsonfile)[1]
data_graph_gen = result["graph_gen"]
l = length(data_graph_gen)
data_graph_gen = getfield.(getindex.(Ref(data_graph_gen), SCATTERING_PROCESSES[1:l]), :times)
data_graph_gen = mean.(data_graph_gen)

# function gen times
@load "bench.jld2"

data_fgen = result["f_gen"]
l = length(data_fgen)
data_fgen = getfield.(getindex.(Ref(data_fgen), SCATTERING_PROCESSES[1:l]), :times)
data_fgen = mean.(data_fgen)

# function  compile time
l = length(comp_times)
data_compile = getindex.(Ref(comp_times), SCATTERING_PROCESSES[1:l])
for i in eachindex(data_compile)
    data_compile[i] = data_compile[i] *= 1e9 # convert to nanoseconds
end
data_compile = median.(data_compile)
data_graph_gen = data_graph_gen[1:l]
data_fgen = data_fgen[1:l]

# normalize
data_sum = data_compile .+ data_graph_gen .+ data_fgen
data_compile ./= data_sum / 100.0
data_graph_gen ./= data_sum / 100.0
data_fgen ./= data_sum / 100.0

# plot
f = Figure()

ax = Axis(
    f[1, 1];
    xlabel="number of incoming photons",
    ylabel="total time",
    limits=(nothing, _find_y_lims(data_sum)),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
    yticks=(yticks1, yticks2),
)

sc = scatter!(ax, [(1:l)...], data_sum)

ax2 = Axis(
    f[1, 1];
    yaxisposition=:right,
    ylabel="ratios of time taken",
    limits=(nothing, (0, 100)),
    yticks=([0, 50, 100], [L"0%", L"50%", L"100%"]),
)
hidespines!(ax2)
hidexdecorations!(ax2)
linkxaxes!(ax, ax2)

colors = Makie.wong_colors()

categories = repeat(1:l, 3)
height = [
    data_graph_gen
    data_fgen
    data_compile
]
grp = vcat([[i for _ in 1:l] for i in 1:3]...)

barplot!(#
    ax2,
    categories,
    height;
    stack=grp,
    color=colors[grp],
    alpha=0.3,
)

# Legend
labels = ["CDAG Generation", "Function Generation", "Function Compilation", "Total Time"]
elements = [
    [PolyElement(; polycolor=colors[i]) for i in 1:(length(labels) - 1)]
    sc
]

Legend(f[1, 2], elements, labels)

save(joinpath(plotpath, "generation_times_total.pdf"), f)
