using ComputableDAGs
using QEDFeynman
using RuntimeGeneratedFunctions
using Plots
using DataFrames
using BenchmarkTools
using QEDcore, QEDprocesses
using Logging
using JLD2

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

# ------------------

df = DataFrame()

MODEL = PerturbativeQED()

SCATTERING_PROCESSES = [
    parse_process("ke->ke", QEDModel()),
    parse_process("kke->ke", QEDModel()),
    parse_process("kkke->ke", QEDModel()),
    #parse_process("kkkke->ke", QEDModel()),
]

CLOSURE_SIZES = (0, 100, 1000)

SUITE = BenchmarkGroup()
SUITE["graph_gen"] = BenchmarkGroup()
SUITE["f_gen"] = BenchmarkGroup()
SUITE["f_exec"] = BenchmarkGroup()

for INSTANCE in SCATTERING_PROCESSES
    println("$INSTANCE")
    SUITE["graph_gen"][string(INSTANCE)] = @benchmarkable graph(proc) setup = (
        proc = $INSTANCE
    )

    g = graph(INSTANCE)

    for CLOSURE_SIZE in CLOSURE_SIZES
        SUITE["f_gen"][string(CLOSURE_SIZE)] = @benchmarkable get_compute_function(
            g_, proc, machine, @__MODULE__; closures_size=CS
        ) setup = (g_ = $g; proc = $INSTANCE; machine = cpu_st(); CS = $CLOSURE_SIZE)

        psp = PhaseSpacePoint(
            INSTANCE,
            MODEL,
            PhasespaceDefinition(SphericalCoordinateSystem(), ElectronRestFrame()),
            tuple((rand(SFourMomentum) for _ in 1:number_incoming_particles(INSTANCE))...),
            tuple((rand(SFourMomentum) for _ in 1:number_outgoing_particles(INSTANCE))...),
        )

        func = get_compute_function(
            g, INSTANCE, cpu_st(), @__MODULE__; closures_size=CLOSURE_SIZE
        )

        SUITE["f_exec"][string(CLOSURE_SIZE)] = @benchmarkable f(input) setup = (
            f = $func; input = $psp
        )
    end
end

tune!(SUITE)
result = run(SUITE; verbose=true)

BenchmarkTools.save("bench.json", result)
@save "bench.jld2" result
