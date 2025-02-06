using Pkg: Pkg
Pkg.activate("$(@__DIR__)/../..")

using ComputableDAGs
using QEDFeynman
using QEDcore, QEDprocesses

using BenchmarkTools
using JLD2

using CairoMakie
using BenchmarkPlots
using LaTeXStrings

jsonfile = "$(@__DIR__)/data/bench.json"

include("$(@__DIR__)/../utils.jl")

plotpath = "$(@__DIR__)/plots"
if !isdir(plotpath)
    mkdir(plotpath)
end

_to_vec(s) = [s]

function proc_str(s::String)
    (prefix, suffix) = split(s, "->")
    b_count = count(c -> c == 'B', suffix)

    if b_count > 1
        prefix = replace(prefix, r"B+" => "B^$b_count")
    end

    return L"%$(b_count)"
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

SCATTERING_PROCESSES = ["AB->AB", "AB->ABBB", "AB->ABBBBB", "AB->ABBBBBBB", "AB->ABBBBBBBBB"]

include("plotting/graph_gen.jl")
include("plotting/f_gen.jl")
include("plotting/f_exec.jl")
include("plotting/f_exec_per_line.jl")
include("plotting/f_gen_per_line.jl")
include("plotting/graph_size.jl")
include("plotting/graph_size_w_ratio.jl")
include("plotting/compile_time.jl")
include("plotting/gen_total.jl")
