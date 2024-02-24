"""
    InteractionParams

An abstract type representing all interaction parameter types.
"""
abstract type InteractionParams end

"""
    GraphParams

An abstract type representing the class of graph interaction parameters.
"""
abstract type GraphParams <: InteractionParams end #for static interaction models, abm interaction models will come next


"""
    CompleteParams

Type to define and store graph interaction parameters for a complete graph.
"""
struct CompleteParams <: GraphParams 
    graph_type::Symbol
    function CompleteParams()
        return new(:complete)
    end
    function CompleteParams(::Symbol)
        return new(:complete)
    end
end

"""
    ErdosRenyiParams

Type to define and store graph interaction parameters for an Erdos-Renyi random graph.
"""
struct ErdosRenyiParams <: GraphParams
    graph_type::Symbol
    λ::Float64
    function ErdosRenyiParams(λ::Float64)
        return new(:er, λ)
    end
    function ErdosRenyiParams(::Symbol, λ::Float64)
        return new(:er, λ)
    end
end

"""
    SmallWorldParams

Type to define and store graph interaction parameters for a small-world (Watts-Strogatz) random graph.
"""
struct SmallWorldParams <: GraphParams
    graph_type::Symbol
    κ::Int
    β::Float64
    function SmallWorldParams(κ::Int, β::Float64)
        return new(:sw, κ, β)
    end
    function SmallWorldParams(::Symbol, κ::Int, β::Float64)
        return new(:sw, κ, β)
    end
end

"""
    ScaleFreeParams

Type to define and store graph interaction parameters for a scale-free random graph.
"""
struct ScaleFreeParams <: GraphParams
    graph_type::Symbol
    α::Float64
    d::Float64 #edge density
    function ScaleFreeParams(α::Float64, d::Float64)
        return new(:sf, α, d)
    end
    function ScaleFreeParams(::Symbol, α::Float64, d::Float64)
        return new(:sf, α, d)
    end
end

"""
    StochasticBlockModelParams

Type to define and store graph interaction parameters for a stochastic block model random graph.
"""
struct StochasticBlockModelParams <: GraphParams
    graph_type::Symbol
    communities::Int
    internal_λ::Float64
    external_λ::Float64
    function StochasticBlockModelParams(communities::Int, internal_λ::Float64, external_λ::Float64)
        return new(:sbm, communities, internal_λ, external_λ)
    end
    function StochasticBlockModelParams(::Symbol, communities::Int, internal_λ::Float64, external_λ::Float64)
        return new(:sbm, communities, internal_λ, external_λ)
    end
end


# struct LatticeParams <: GraphParams
#     graph_type::Symbol
#     dimensions::Int
#     dim_lengths::Vector{Int}
#     function LatticeParams(dim_lengths::Vector{Int})
#         return new(:lattice, length(dim_lengths), dim_lengths)
#     end
# end
    

##########################################
# GraphParams Accessors
##########################################

"""
    graph_type(graph_params::GraphParams)

Get the graph type of a GraphParams instance.
"""
graph_type(graph_params::GraphParams) = getfield(graph_params, :graph_type) #dont need graph type in these types. can do typeof(graph_params) or something

"""
    λ(erdos_renyi_params:ErdosRenyiParams)

Get the λ parameter value of an ErdosRenyiParams instance.

λ = edge_probability * number_agents
"""
λ(erdos_renyi_params::ErdosRenyiParams) = getfield(erdos_renyi_params, :λ)

"""
    κ(small_world_params:SmallWorldParams)

Get the κ parameter value of a SmallWorldParams instance.

κ = expected degree per vertex
"""
κ(small_world_params::SmallWorldParams) = getfield(small_world_params, :κ)

"""
    β(small_world_params:SmallWorldParams)

Get the β parameter value of a SmallWorldParams instance.

β = edge probability
"""
β(small_world_params::SmallWorldParams) = getfield(small_world_params, :β)

"""
    α(scale_free_params:ScaleFreeParams)

Get the α parameter value of a ScaleFreeParams instance.

α = exponent for expected power law degree distribution
"""
α(scale_free_params::ScaleFreeParams) = getfield(scale_free_params, :α)

"""
    d(scale_free_params:ScaleFreeParams)

Get the d parameter value of a ScaleFreeParams instance.

d = expected edge density
"""
d(scale_free_params::ScaleFreeParams) = getfield(scale_free_params, :d)

"""
    communities(stochastic_block_model_params:StochasticBlockModelParams)

Get the number of communities defined for a StochasticBlockModelParams instance.
"""
communities(stochastic_block_model_params::StochasticBlockModelParams) = getfield(stochastic_block_model_params, :communities)

"""
    internal_λ(stochastic_block_model_params:StochasticBlockModelParams)

Get the internal_λ parameter value of a StochasticBlockModelParams instance.

internal_λ = λ parameter within communities
"""
internal_λ(stochastic_block_model_params::StochasticBlockModelParams) = getfield(stochastic_block_model_params, :internal_λ)

"""
    external_λ(stochastic_block_model_params:StochasticBlockModelParams)

Get the external_λ parameter value of a StochasticBlockModelParams instance.

external_λ = λ parameter between communities
"""
external_λ(stochastic_block_model_params::StochasticBlockModelParams) = getfield(stochastic_block_model_params, :external_λ)


"""
    displayname(graph_params::GraphParams)

Get the string used for displaying a GraphParams instance.
"""
displayname(::CompleteParams) = "Complete"
displayname(graph_params::ErdosRenyiParams) = "ErdosRenyi λ=$(λ(graph_params))"
displayname(graph_params::SmallWorldParams) = "SmallWorld κ=$(κ(graph_params)) β=$(β(graph_params))"
displayname(graph_params::ScaleFreeParams) = "ScaleFree α=$(α(graph_params)) d=$(d(graph_params))"
displayname(graph_params::StochasticBlockModelParams) = "StochasticBlockModel communities=$(communities(graph_params)) internal_λ=$(internal_λ(graph_params)) external_λ=$(external_λ(graph_params))"

Base.show(graph_params::GraphParams) = println(displayname(graph_params))
