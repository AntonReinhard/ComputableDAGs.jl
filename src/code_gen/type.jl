
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
    @inline function NoInit{T}() where {T}
        return new{T}()
    end
    @inline function NoInit{T}(val::T) where {T}
        return new{T}(val)
    end
end

@inline Base.getindex(w::NoInit{T}) where {T} = w.val
@inline Base.setindex!(w::NoInit{T}, val::T) where {T} = (w.val = val; w)
@inline Base.convert(::Type{NoInit{T}}, val::T) where {T} = NoInit{T}(val)
@inline Base.convert(::Type{T}, val::NoInit{T}) where {T} = val[]

@inline _deref(v) = v
@inline _deref(ni::NoInit{T}) where {T} = ni[]
@inline _deref(r::Ref{T}) where {T} = _deref(r[])
@inline _set_deref!(v::Ref{T}, val::T) where {T} = v[] = val
@inline _set_deref!(v::NoInit{T}, val::T) where {T} = v[] = val
@inline _set_deref!(v::Ref{NoInit{T}}, val) where {T} = _set_deref!(v[], val)
