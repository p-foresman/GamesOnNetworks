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
    function ScaleFreeParams(α::Float64)
        return new(:sf, α)
    end
    function ScaleFreeParams(::Symbol, α::Float64)
        return new(:sf, α)
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
struct LatticeParams <: GraphParams
    graph_type::Symbol
    dimensions::Int
    dim_lengths::Vector{Int}
    function LatticeParams(dim_lengths::Vector{Int})
        return new(:lattice, length(dim_lengths), dim_lengths)
    end
end
    
"""
GraphParams Accessors
"""
graph_type(graph_params::GraphParams) = graph_params.graph_type #dont need graph type in these types. can do typeof(graph_params) or something

# methods to return displayable names as strings for graph types, etc. (similar to .__str__() in Python)
function displayName(::CompleteParams) return "Complete" end
function displayName(graph_params::ErdosRenyiParams) return "ErdosRenyi λ=$(graph_params.λ)" end
function displayName(graph_params::SmallWorldParams) return "SmallWorld κ=$(graph_params.κ) β=$(graph_params.β)" end
function displayName(graph_params::ScaleFreeParams) return "ScaleFree α=$(graph_params.α)" end
function displayName(graph_params::StochasticBlockModelParams) return "StochasticBlockModel communities=$(graph_params.communities) internal_λ=$(graph_params.internal_λ) external_λ=$(graph_params.external_λ)" end
