function _read_graphml_header_ext(root::EzXML.Node, attr_name_type::String, attr_name_tasktype::String, attr_name_tasklength::String)
    type_attr_str = ""
    tasktype_attr_str = ""
    tasklength_attr_str = ""

    graph_elem = nothing
    for child in eachelement(root)
        if child.name == "key"
            if child["for"] == "node" && child["attr.name"] == attr_name_type
                type_attr_str = child["id"]
            elseif child["for"] == "node" && child["attr.name"] == attr_name_tasktype
                tasktype_attr_str = child["id"]
            elseif child["for"] == "node" && child["attr.name"] == attr_name_tasklength
                tasklength_attr_str = child["id"]
            end
        end
        # the main node that contains the graph structure
        if child.name == "graph"
            graph_elem = child
            break
        end
    end

    if graph_elem === nothing
        error("GraphML file $filename: no <graph> element found under root")
    end
    if type_attr_str == ""
        error("GraphML file $filename: no <key> element with the attr.name \"$attr_name_type\" found")
    end
    if tasktype_attr_str == ""
        error("GraphML file $filename: no <key> element with the attr.name \"$attr_name_tasktype\" found")
    end
    if tasklength_attr_str == ""
        error("GraphML file $filename: no <key> element with the attr.name \"$attr_name_tasklength\" found")
    end

    return graph_elem, type_attr_str, tasktype_attr_str, tasklength_attr_str
end


function _task_length(node::EzXML.Node, tasklength_attr_str::String)
    for d in eachelement(node)
        if !haskey(d, "key")
            continue
        end
        if (d["key"] == tasklength_attr_str)
            return parse(Float64, d.content)
        end
    end
    @warn "found compute node (id=$(node["id"]) without a valid task length, no key with $(tasklength_attr_str) was found"
    # use small tasklength, idk what else to do here
    return 1.0e-6
end

function task_lengths(
        filename::String;
        attr_name_type::String = "type",
        attr_name_tasktype::String = "node_id",
        attr_name_length::String = "runtime_average_s",
        type_compute_identifier::String = "Algorithm",
        type_data_identifier::String = "DataObject",
    )
    # store task length per task name
    task_length_dict = Dict{String, Float64}()

    doc = readxml(filename)
    root = EzXML.root(doc)
    graph_elem, type_attr_str, tasktype_attr_str, tasklength_attr_str = _read_graphml_header_ext(root, attr_name_type, attr_name_tasktype, attr_name_length)

    # Iterate over all nodes
    for node_elem in eachelement(graph_elem)
        if (node_elem.name != "node")
            continue
        end

        node_type = ComputableDAGs._node_type(node_elem, type_attr_str, type_compute_identifier, type_data_identifier)
        if node_type != ComputableDAGs.COMPUTE_NODE
            continue
        end

        task_name = ComputableDAGs._sanitize_name(ComputableDAGs._task_type(node_elem, tasktype_attr_str))
        task_length_dict[task_name] = _task_length(node_elem, tasklength_attr_str)
    end
    return task_length_dict
end
