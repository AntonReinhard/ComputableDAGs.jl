using Distributed
using ComputableDAGs
using Pkg
Pkg.develop(; path="/home/reinha57/repos/QEDFeynman.jl/")
using QEDFeynman
using RuntimeGeneratedFunctions
using DataFrames
using BenchmarkTools
using QEDcore, QEDprocesses
using Logging
using JLD2

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 120.0

RuntimeGeneratedFunctions.init(@__MODULE__)

global_logger(NullLogger())

#=
function profile(instance, input, optimizer, closures_size)
    b_gen = @benchmark graph($instance)
    g = graph(instance)

    if !isnothing(optimizer)
        # compile run first
        begin
            g_temp = graph(instance)
            optimize_to_fixpoint!(optimizer, g_temp)
        end

        t_optimization = @elapsed optimize_to_fixpoint!(optimizer, g)
    else
        t_optimization = 0.0
    end

    g_props = get_properties(g)

    b_fgen = @benchmark get_compute_function(
        $g, $instance, cpu_st(), @__MODULE__; closures_size=$closures_size
    )
    f = get_compute_function(
        g, instance, cpu_st(), @__MODULE__; closures_size=closures_size
    )

    tic = time_ns()
    f(input)
    toc = time_ns()
    t_compile = toc - tic

    b_exec = @benchmark $f($input)

    return (
        instance=string(instance),
        optimizer=string(optimizer),
        closures_size=closures_size,
        b_gen=b_gen,
        t_optimization=t_optimization,
        g_props=g_props,
        b_fgen=b_fgen,
        t_compile=t_compile,
        b_exec=b_exec,
    )
end
=#

function time_compilation(expr; setup=nothing)
    ps = addprocs(1)
    remotecall_fetch(only(ps)) do
        @eval begin
            using QEDprocesses, QEDcore, ComputableDAGs, QEDFeynman
        end
    end

    (; compile_time) = remotecall_fetch(only(ps)) do
        @eval begin
            $setup
            @timed $expr
        end
    end
    rmprocs(ps)
    return compile_time
end

function bench_compilation(expr; setup=nothing, n=20)
    times = Float64[]
    for _ in 1:n
        push!(times, time_compilation(expr; setup=setup))
    end

    return times
end

# ------------------

df = DataFrame()

MODEL = PerturbativeQED()

SCATTERING_PROCESSES = [
    "ke->ke",               # 1
    "kke->ke",              # 2
    "kkke->ke",             # 3
    "kkkke->ke",            # 4
    "kkkkke->ke",           # 5
    "kkkkkke->ke",          # 6
    "kkkkkkke->ke",         # 7
    "kkkkkkkke->ke",        # 8
    #"kkkkkkkkke->ke",       # 9
]

SUITE = BenchmarkGroup()
SUITE["graph_gen"] = BenchmarkGroup()

graph_props = Dict{String,GraphProperties}()
comp_times = Dict{String,Vector{Float64}}()
node_dicts = Dict{String,Dict{Type,Int64}}()

for INSTANCE_STR in SCATTERING_PROCESSES
    INSTANCE = parse_process(INSTANCE_STR, QEDModel())
    println("$INSTANCE_STR")
    graph(INSTANCE)
    SUITE["graph_gen"][INSTANCE_STR] = @benchmarkable graph(proc) setup = (proc = $INSTANCE; GC.gc())

    g = graph(INSTANCE)
    graph_props[INSTANCE_STR] = get_properties(g)

    node_dicts[INSTANCE_STR] = Dict{Type,Int64}()
    for node in g.nodes
        if haskey(node_dicts[INSTANCE_STR], typeof(task(node)))
            node_dicts[INSTANCE_STR][typeof(task(node))] = node_dicts[INSTANCE_STR][typeof(task(node))] + 1
        else
            node_dicts[INSTANCE_STR][typeof(task(node))] = 1
        end
    end

    psp = PhaseSpacePoint(
        INSTANCE,
        MODEL,
        PhasespaceDefinition(SphericalCoordinateSystem(), ElectronRestFrame()),
        tuple((rand(SFourMomentum) for _ in 1:number_incoming_particles(INSTANCE))...),
        tuple((rand(SFourMomentum) for _ in 1:number_outgoing_particles(INSTANCE))...),
    )

    func = get_compute_function(g, INSTANCE, cpu_st(), @__MODULE__; closures_size=0)

    SUITE["f_gen"][INSTANCE_STR] = @benchmarkable get_compute_function(g_, proc, machine, @__MODULE__; closures_size=0) setup = (
        g_ = $g; proc = $INSTANCE; machine = cpu_st(); GC.gc()
    )

    if graph_props[INSTANCE_STR].number_of_nodes > 30000
        continue
    end

    comp_times[INSTANCE_STR] = bench_compilation(
        :(f(p));
        setup=quote
            using QEDcore, QEDprocesses, RuntimeGeneratedFunctions
            RuntimeGeneratedFunctions.init(@__MODULE__)
            p = PhaseSpacePoint(
                $INSTANCE,
                $MODEL,
                PhasespaceDefinition(SphericalCoordinateSystem(), ElectronRestFrame()),
                tuple((rand(SFourMomentum) for _ in 1:number_incoming_particles($INSTANCE))...),
                tuple((rand(SFourMomentum) for _ in 1:number_outgoing_particles($INSTANCE))...),
            )
            f = get_compute_function($g, $INSTANCE, cpu_st(), @__MODULE__; closures_size=0)
        end,
    )
    println("collected $(length(comp_times[INSTANCE_STR])) compile time samples")
    SUITE["f_exec"][INSTANCE_STR] = @benchmarkable f(input) setup = (f = $func; input = $psp; GC.gc())
end

tune!(SUITE)
result = run(SUITE; verbose=true)

BenchmarkTools.save("bench.json", result)
@save "bench.jld2" result graph_props node_dicts comp_times
