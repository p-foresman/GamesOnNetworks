




struct Registry
    graphs::Vector{Type{GraphParams}}

    function Registry()
        return new([])
    end
end
const registry = Registry()


function register!(registry::Registry, graph::Type{GraphParams})
    append!(registry.graphs, graph)
end

# register!(registry, CompleteParams)

macro register(registry::Registry, graph_params::Any)
    quote
        println("$(registry), $(graph_params)")
    end
end