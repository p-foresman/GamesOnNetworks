abstract type InteractionParams end

abstract type GraphParams <: InteractionParams end #for static interaction models, abm interaction models will come next


struct CompleteParams <: GraphParams 
    graph_type::Symbol
    function CompleteParams()
        return new(:complete)
    end
    function CompleteParams(::Symbol)
        return new(:complete)
    end
end
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
    
"""
GraphParams Accessors
"""
graph_type(graph_params::GraphParams) = getfield(graph_params, :graph_type) #dont need graph type in these types. can do typeof(graph_params) or something

λ(erdos_renyi_params::ErdosRenyiParams) = getfield(erdos_renyi_params, :λ)

κ(small_world_params::SmallWorldParams) = getfield(small_world_params, :κ)
β(small_world_params::SmallWorldParams) = getfield(small_world_params, :β)

α(scale_free_params::ScaleFreeParams) = getfield(scale_free_params, :α)
d(scale_free_params::ScaleFreeParams) = getfield(scale_free_params, :d)

communities(stochastic_block_model_params::StochasticBlockModelParams) = getfield(stochastic_block_model_params, :communities)
internal_λ(stochastic_block_model_params::StochasticBlockModelParams) = getfield(stochastic_block_model_params, :internal_λ)
external_λ(stochastic_block_model_params::StochasticBlockModelParams) = getfield(stochastic_block_model_params, :external_λ)



displayname(::CompleteParams) = "Complete"
displayname(graph_params::ErdosRenyiParams) = "ErdosRenyi λ=$(λ(graph_params))"
displayname(graph_params::SmallWorldParams) = "SmallWorld κ=$(κ(graph_params)) β=$(β(graph_params))"
displayname(graph_params::ScaleFreeParams) = "ScaleFree α=$(α(graph_params)) d=$(d(graph_params))"
displayname(graph_params::StochasticBlockModelParams) = "StochasticBlockModel communities=$(communities(graph_params)) internal_λ=$(internal_λ(graph_params)) external_λ=$(external_λ(graph_params))"
Base.show(graph_params::GraphParams) = println(displayname(graph_params))
