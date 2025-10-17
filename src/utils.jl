"""
    bytes_to_human_readable(bytes)

Return a human readable string representation of the given number.

```jldoctest
julia> using ComputableDAGs

julia> ComputableDAGs.bytes_to_human_readable(4096)
"4.0 KiB"
```
"""
function bytes_to_human_readable(bytes)
    units = ["B", "KiB", "MiB", "GiB", "TiB"]
    unit_index = 1
    while bytes >= 1024 && unit_index < length(units)
        bytes /= 1024
        unit_index += 1
    end
    return string(round(bytes; sigdigits = 4), " ", units[unit_index])
end

"""
    _lt_node_tuples(n1::Tuple{Node, Int}, n2::Tuple{Node, Int})

Less-Than comparison between nodes with indices.
"""
function _lt_node_tuples(n1::Tuple{UUID, Int}, n2::Tuple{UUID, Int})
    if n1[2] == n2[2]
        return n1[1] < n2[1]
    else
        return n1[2] < n2[2]
    end
end

"""
    sort_node!(node::Node)

Sort the nodes' parents and children vectors. The vectors are mostly very short so sorting does not take a lot of time.
Sorted nodes are required to make the finding of [`NodeReduction`](@ref)s a lot faster using the [`NodeTrie`](@ref) data structure.
"""
function sort_node!(node::Node)
    sort!(node.children; lt = _lt_node_tuples)
    return sort!(node.parents)
end

"""
    unroll_symbol_vector(vec::Vector{Symbol})

Return the given vector as single String without quotation marks or brackets.
"""
function unroll_symbol_vector(vec::VEC) where {VEC <: Union{AbstractVector, Tuple}}
    return Expr(:tuple, vec...)
end

function _sanitize_name(s::String)
    ## WARN: ai generated, surely this is simple enough for an AI to write correctly

    # List of Julia reserved keywords
    keywords = Set(
        [
            "if", "else", "elseif", "while", "for", "begin", "end", "try", "catch", "finally",
            "return", "break", "continue", "function", "macro", "quote", "let", "local",
            "global", "const", "do", "module", "baremodule", "using", "import", "export",
            "struct", "mutable", "primitive", "type", "abstract", "where", "isa", "in",
            "new", "typealias",
        ]
    )

    # Replace invalid characters with underscore
    s_clean = replace(s, r"[^\w]" => "_")

    # Remove leading characters until we hit a valid start (letter or underscore)
    s_clean = replace(s_clean, r"^[^A-Za-z_]+" => "")

    # If string becomes empty or starts with a digit, prepend underscore
    if isempty(s_clean) || isnumeric(first(s_clean))
        s_clean = "_" * s_clean
    end

    # If it's a keyword, append underscore
    if s_clean in keywords
        s_clean *= "_"
    end

    return s_clean
end
