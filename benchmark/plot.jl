using Pkg: Pkg
Pkg.activate(".")

using ComputableDAGs
using QEDFeynman
using QEDcore, QEDprocesses

using BenchmarkTools
using JLD2

using PythonPlot: PythonPlot
using CairoMakie
plotly()
using BenchmarkPlots

include("utils.jl")

plotpath = "plots"
if !isdir(plotpath)
    mkdir(plotpath)
end

_to_vec(s) = [s]

function proc_str(s::String)
    s = replace(s, "e" => "e^-")
    s = replace(s, "k" => "γ")

    (prefix, suffix) = split(s, "->")
    k_count = count(c -> c == 'γ', prefix)

    if k_count > 1
        prefix = replace(prefix, r"γ+" => "γ^$k_count")
    end

    return "\$$(k_count)\$"
end

yticks1 = [1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, 1e13]
yticks2 = [
    "\$1ns\$",
    "\$10ns\$",
    "\$100ns\$",
    "\$1μs\$",
    "\$10μs\$",
    "\$100μs\$",
    "\$1ms\$",
    "\$10ms\$",
    "\$100ms\$",
    "\$1s\$",
    "\$10s\$",
    "\$100s\$",
    "\$1ks\$",
    "\$10ks\$",
]

SCATTERING_PROCESSES = [
    "ke->ke", "kke->ke", "kkke->ke", "kkkke->ke", "kkkkke->ke", "kkkkkke->ke", "kkkkkkke->ke", "kkkkkkkke->ke"
]

result = BenchmarkTools.load("bench.json")[1]

# == Graph Generation Time ==
data = result["graph_gen"]
l = length(data)
data = getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times)
data = mean.(data)
P = scatter(
    [(1:l)...],
    data;
    yscale=:log10,
    ylim=_find_y_lims(data),
    #yguide="t",
    yminorgrid=true,
    yguide="graph generation time",
    xguide="number of incoming photons",
    framestyle=:box,
    legend=false,
    outliers=false,
)
xticks!(P, [(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l]))
yticks!(P, yticks1, yticks2)
#plot!(P; title="DAG Generation Time for \$e^-γ^n \\to e^-γ\$")
savefig(joinpath(plotpath, "graph_gen_compton.pdf"))

# == Function Execution Time ==
data = result["f_exec"]
l = length(data)
data = getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times)
data = mean.(data)
P = scatter(
    [(1:l)...],
    data;
    yscale=:log10,
    ylim=_find_y_lims(data),
    #yguide="t",
    yminorgrid=true,
    yguide="function execution time",
    xguide="number of incoming photons",
    framestyle=:box,
    legend=false,
    outliers=false,
)
xticks!(P, [(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l]))
yticks!(P, yticks1, yticks2)
#plot!(P; title="Function Execution Time for \$e^-γ^n \\to e^-γ\$")
savefig(joinpath(plotpath, "f_exec_compton.pdf"))

# == Function Generation Time ==
data = result["f_gen"]
l = length(data)
data = getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times)
data = mean.(data)
P = scatter(
    [(1:l)...],
    data;
    yscale=:log10,
    ylim=_find_y_lims(data),
    #yguide="t",
    yminorgrid=true,
    yguide="function generation time",
    xguide="number of incoming photons",
    framestyle=:box,
    legend=false,
    outliers=false,
)
xticks!(P, [(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l]))
yticks!(P, yticks1, yticks2)
#plot!(P; title="Function Generation Time for \$e^-γ^n \\to e^-γ\$")
savefig(joinpath(plotpath, "f_gen_compton.pdf"))

@load "bench.jld2"

# == Function Generation Time per Line ==
data = copy(result["f_gen"])
l = length(data)
data = getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times)
data_x = getfield.(getindex.(Ref(graph_props), SCATTERING_PROCESSES), :number_of_nodes)
for i in eachindex(data)
    data[i] = data[i] ./ data_x[i]
end
data = median.(data)
P = scatter(
    [(1:l)...],
    data;
    yscale=:log10,
    ylim=(1e4, 1e6),
    #yguide="t",
    yminorgrid=true,
    yguide="function generation time\naveraged over number of nodes",
    xguide="number of incoming photons",
    framestyle=:box,
    legend=false,
    outliers=false,
)
xticks!(P, [(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l]))
yticks!(P, yticks1, yticks2)
#plot!(P; title="Function Generation Time for \$e^-γ^n \\to e^-γ\$")
savefig(joinpath(plotpath, "f_gen_per_line.pdf"))

# == Graph Size ==
data = getfield.(getindex.(Ref(graph_props), SCATTERING_PROCESSES), :number_of_nodes)
l = length(data)
P = scatter(
    [(1:l)...],
    data;
    yscale=:log10,
    ylim=_find_y_lims(data),
    yminorgrid=true,
    yguide="number of nodes in the CDAG",
    xguide="number of incoming photons",
    legend=false,
)
xticks!(P, [(1:length(SCATTERING_PROCESSES))...], proc_str.(SCATTERING_PROCESSES))

data = Vector{Dict{Type,Float64}}()
for dict in getindex.(Ref(node_dicts), SCATTERING_PROCESSES)
    s = sum(values(dict))
    new_dict = Dict{Type,Float64}()
    for k in keys(dict)
        new_dict[k] = dict[k] / s
    end
    push!(data, new_dict)
end

P = groupedbar!(#
    twinx(),
    [[d[ComputableDAGs.DataTask] for d in data] [d[ComputeTaskQED_U] for d in data] [d[ComputeTaskQED_V] for d in data] [d[ComputeTaskQED_Sum] for d in data] [get(d, ComputeTaskQED_S1, zero(Float64)) for d in data] [d[ComputeTaskQED_S2] for d in data]];
    axis=:right,
    yscale=:lin,
    ylim=(0, 100),
    yguide="ratios of node types",
    legend=:topright,
)

#plot!(P; title="DAG Size for \$e^-γ^n \\to e^-γ\$")
savefig(joinpath(plotpath, "graph_size_compton.pdf"))

# == Function Compile Time ==
l = length(comp_times)
data = getindex.(Ref(comp_times), SCATTERING_PROCESSES[1:l])
for i in eachindex(data)
    data[i] = data[i] *= 1e9 # convert to nanoseconds
end
data = median.(data)
P = scatter(
    [(1:l)...],
    data;
    yscale=:log10,
    ylim=_find_y_lims(data),
    yminorgrid=true,
    yguide="function copmile time",
    xguide="number of incoming photons",
    framestyle=:box,
    legend=false,
    outliers=false,
)
xticks!(P, [(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l]))
yticks!(P, yticks1, yticks2)
savefig(joinpath(plotpath, "f_compile_compton.pdf"))

# TODO framestyle box (wenn eine achse)
# TODO minorticks bei log y achse
# TODO boxplots zu 
