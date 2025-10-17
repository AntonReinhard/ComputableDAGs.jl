using ComputableDAGs
using EzXML

#filename = "./data/ATLAS/q449/df.graphml"
filename = "./data/FCC/ALLEGRO_o1_v3/df.graphml"

include("helpers.jl")
include("cpu_crunch.jl")


@info "Setting up tasks"

for (name, seconds) in task_lengths(filename)
    @info "task name: $name"
    eval(Meta.parse("
begin
    struct $name <: ComputableDAGs.AbstractComputeTask end
    ComputableDAGs.compute(::$name, args...) = crunch_for_seconds($seconds, COEFFS)
    ComputableDAGs.compute_effort(::$name) = $seconds
end
"))
end

@info "Built tasks"

struct Demo end

ComputableDAGs.input_expr(::Demo, ::String, ::Symbol) = :(nothing)
ComputableDAGs.input_type(::Demo) = Nothing

cdag = read_graphml(filename, @__MODULE__)

@info "Read graph"
@show cdag

f = compute_function(cdag, Demo(), cpu_st(), @__MODULE__)


@info "First run (compilation)"
@time f(nothing)

@info "Benchmarking"
using BenchmarkTools

b = @benchmark f(nothing)

display(b)
@info "Compared to expected time: $(get_properties(cdag).compute_effort)"
