using Pkg: Pkg
Pkg.activate(".")

using ComputableDAGs
using QEDFeynman
using QEDcore, QEDprocesses

using BenchmarkTools
using BenchmarkPlots, StatsPlots
using JLD2

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

yticks1 = [1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11]
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
]

SCATTERING_PROCESSES = [
    "ke->ke",
    "kke->ke",
    "kkke->ke",
    "kkkke->ke",
    "kkkkke->ke",
    "kkkkkke->ke",
    "kkkkkkke->ke",
]

result = BenchmarkTools.load("bench.json")[1]

data = result["graph_gen"]
l = length(data)
P = violin(
    _to_vec.([(1:l)...]),
    getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times);
    yscale=:log10,
    ylim=_find_y_lims(data),
    #yguide="t",
    xguide="number of incoming photons",
    legend=false,
)
xticks!(P, [(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l]))
yticks!(P, yticks1, yticks2)
#plot!(P; title="DAG Generation Time for \$e^-γ^n \\to e^-γ\$")
savefig(joinpath(plotpath, "graph_gen_compton.pdf"))

data = result["f_exec"]
l = length(data)
P = violin(
    _to_vec.([(1:l)...]),
    getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times);
    yscale=:log10,
    ylim=_find_y_lims(data),
    #yguide="t",
    xguide="number of incoming photons",
    legend=false,
)
xticks!(P, [(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l]))
yticks!(P, yticks1, yticks2)
#plot!(P; title="Function Execution Time for \$e^-γ^n \\to e^-γ\$")
savefig(joinpath(plotpath, "f_exec_compton.pdf"))

data = result["f_gen"]
l = length(data)
P = violin(
    _to_vec.([(1:l)...]),
    getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times);
    yscale=:log10,
    ylim=_find_y_lims(data),
    #yguide="t",
    xguide="number of incoming photons",
    legend=false,
)
xticks!(P, [(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l]))
yticks!(P, yticks1, yticks2)
#plot!(P; title="Function Generation Time for \$e^-γ^n \\to e^-γ\$")
savefig(joinpath(plotpath, "f_gen_compton.pdf"))

@load "bench.jld2"

data = getfield.(getindex.(Ref(graph_props), SCATTERING_PROCESSES), :number_of_nodes)
P = scatter(
    [(1:l)...],
    data;
    yscale=:log10,
    ylim=_find_y_lims(data),
    #yguide="#",
    xguide="number of incoming photons",
    legend=false,
)
xticks!(P, [(1:length(SCATTERING_PROCESSES))...], proc_str.(SCATTERING_PROCESSES))
#plot!(P; title="DAG Size for \$e^-γ^n \\to e^-γ\$")
savefig(joinpath(plotpath, "graph_size_compton.pdf"))
