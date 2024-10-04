
"""
    Tape{INPUT}

TODO: update docs
- `INPUT` the input type of the problem instance

- `code::Vector{Expr}`: The julia expression containing the code for the whole graph.
- `inputSymbols::Dict{String, Vector{Symbol}}`: A dictionary of symbols mapping the names of the input nodes of the graph to the symbols their inputs should be provided on.
- `outputSymbol::Symbol`: The symbol of the final calculated value
"""
struct Tape{INPUT}
    initCachesCode::Vector{Expr}
    inputAssignCode::Vector{FunctionCall}
    schedule::Vector{FunctionCall}
    inputSymbols::Dict{String,Vector{Symbol}}
    outputSymbol::Symbol
    cache::Dict{Symbol,Any}
    instance::Any
    machine::Machine
end

mutable struct NoInit{T}
    val::T
    function NoInit{T}() where {T}
        return new{T}()
    end
    function NoInit{T}(val::T) where {T}
        return new{T}(val)
    end
end

Base.getindex(w::NoInit{T}) where {T} = w.val
Base.setindex!(w::NoInit{T}, val::T) where {T} = w.val = val
Base.convert(::Type{NoInit{T}}, val::T) where {T} = NoInit{T}(val)
Base.convert(::Type{T}, val::NoInit{T}) where {T} = val[]

@inline _deref(v) = v
@inline _deref(ni::NoInit{T}) where {T} = ni[]
