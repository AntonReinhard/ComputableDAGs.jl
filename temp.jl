using AMDGPU
using KernelAbstractions
using ComputableDAGs
ComputableDAGs.init(@__MODULE__)
ComputableDAGs.init_kernel(@__MODULE__)

struct Fibonacci
    n::Int
end

@compute_task Add 1 (+)

function ComputableDAGs.input_expr(::Fibonacci, name::String, input_symbol::Symbol)
    return if (name == "fib(0)")
        :($input_symbol[1])
    elseif (name == "fib(1)")
        :($input_symbol[2])
    else
        assert(false)
    end
end

ComputableDAGs.input_type(::Fibonacci) = Tuple{Int, Int}

function ComputableDAGs.graph(fib::Fibonacci)
    @assert fib.n >= 2
    return @assemble_dag begin
        n1 = @add_entry "fib(0)" 1
        n2 = @add_entry "fib(1)" 1

        for _ in 3:fib.n
            n3 = @add_call Add() 1 n1 n2
            n1 = n2
            n2 = n3
        end
    end
end


function barrier(in::AbstractVector, out::AbstractVector)
    instance = Fibonacci(10)
    dag = graph(instance)

    k = kernel(dag, instance, @__MODULE__)
    k(get_backend(in), 32)(in, out; ndrange = length(in))
    return out
end

N = 16

in = ROCVector([(rand(1:10), rand(1:10)) for i in 1:N])
out = ROCVector([rand(Int) for i in 1:N])
@show barrier(in, out)
