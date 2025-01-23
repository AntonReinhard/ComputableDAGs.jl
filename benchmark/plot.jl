using Pkg: Pkg
Pkg.activate(".")

using ComputableDAGs
using QEDFeynman
using QEDcore, QEDprocesses

using BenchmarkTools
using JLD2

using CairoMakie
using BenchmarkPlots
using LaTeXStrings

jsonfile = "bench.json"

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

    return L"%$(k_count)"
end

yticks1 = [1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, 1e13]
yticks2 = [
    L"1ns",
    L"10ns",
    L"100ns",
    L"1μs",
    L"10μs",
    L"100μs",
    L"1ms",
    L"10ms",
    L"100ms",
    L"1s",
    L"10s",
    L"100s",
    L"1ks",
    L"10ks",
]

SCATTERING_PROCESSES = [
    "ke->ke", "kke->ke", "kkke->ke", "kkkke->ke", "kkkkke->ke", "kkkkkke->ke", "kkkkkkke->ke", "kkkkkkkke->ke"
]

include("plots/graph_gen.jl")

include("plots/f_gen.jl")

include("plots/f_exec.jl")

include("plots/f_gen_per_line.jl")

include("plots/graph_size.jl")

include("plots/compile_time.jl")

include("plots/gen_total.jl")

# TODO framestyle box (wenn eine achse)
