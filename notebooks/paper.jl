using ComputableDAGs
using QEDFeynmanDiagrams
using RuntimeGeneratedFunctions
using Plots
using DataFrames
using BenchmarkTools
using QEDcore, QEDprocesses
using Logging

RuntimeGeneratedFunctions.init(@__MODULE__)

global_logger(NullLogger())

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

    println(f)

    tic = time_ns()
    f(input)
    toc = time_ns()
    t_compile = toc - tic

    b_exec = @benchmark $f($input)

    return (
        instance=string(instance),
        optimizer=optimizer,
        closures_size=closures_size,
        b_gen=b_gen,
        t_optimization=t_optimization,
        g_props=g_props,
        b_fgen=b_fgen,
        t_compile=t_compile,
        b_exec=b_exec,
    )
end

function make_nphoton_compton(n::Int, all_combs::Bool)
    return ScatteringProcess(
        (Electron(), ntuple(_ -> Photon(), n)...),     # incoming particles
        (Electron(), Photon()),                        # outgoing particles
        (
            all_combs ? AllSpin() : SpinUp(),
            ntuple(_ -> all_combs ? AllPol() : PolX(), n)...,
        ),  # incoming particle spin/pols
        (all_combs ? AllSpin() : SpinUp(), all_combs ? AllPol() : PolX()),                         # outgoing particle spin/pols
    )
end

# ------------------

df = DataFrame()

MODEL = PerturbativeQED()

SCATTERING_PROCESSES = [
    make_nphoton_compton(1, false),
    #=make_nphoton_compton(2, false),
    make_nphoton_compton(3, false),
    make_nphoton_compton(4, false),=#
]
for (INSTANCE, OPTIMIZER, CLOSURE_SIZE) in Iterators.product(
    SCATTERING_PROCESSES, (nothing, ReductionOptimizer(), SplitOptimizer()), (0, 100)
)
    psp = PhaseSpacePoint(
        INSTANCE,
        MODEL,
        PhasespaceDefinition(SphericalCoordinateSystem(), ElectronRestFrame()),
        tuple((rand(SFourMomentum) for _ in 1:number_incoming_particles(INSTANCE))...),
        tuple((rand(SFourMomentum) for _ in 1:number_outgoing_particles(INSTANCE))...),
    )
    println("$INSTANCE | $OPTIMIZER | $CLOSURE_SIZE")
    results = profile(INSTANCE, psp, OPTIMIZER, CLOSURE_SIZE)
    push!(df, results)
end

df
