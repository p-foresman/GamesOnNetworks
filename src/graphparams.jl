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
    function ErdosRenyiParams(λ::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        return new(:er, Float64(λ))
    end
    function ErdosRenyiParams(::Symbol, λ::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        return new(:er, Float64(λ))
    end
end

"""
    SmallWorldParams

Type to define and store graph interaction parameters for a small-world (Watts-Strogatz) random graph.
"""
struct SmallWorldParams <: GraphParams
    graph_type::Symbol
    λ::Float64
    β::Float64
    function SmallWorldParams(λ::Real, β::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert 0.0 <= β <= 1.0 "'β' parameter must be between 0.0 and 1.0"
        return new(:sw, Float64(λ), Float64(β))
    end
    function SmallWorldParams(::Symbol, λ::Real, β::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert 0.0 <= β <= 1.0 "'β' parameter must be between 0.0 and 1.0"
        return new(:sw, Float64(λ), Float64(β))
    end
end

"""
    ScaleFreeParams

Type to define and store graph interaction parameters for a scale-free random graph.
"""
struct ScaleFreeParams <: GraphParams
    graph_type::Symbol
    λ::Float64
    α::Float64
    function ScaleFreeParams(λ::Real, α::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert α >= 2 "'α' parameter must be >= 2.0"
        return new(:sf, Float64(λ), Float64(α))
    end
    function ScaleFreeParams(::Symbol, λ::Real, α::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert α >= 2 "'α' parameter must be >= 2.0"
        return new(:sf, Float64(λ), Float64(α))
    end
end

"""
    StochasticBlockModelParams

Type to define and store graph interaction parameters for a stochastic block model random graph.
"""
struct StochasticBlockModelParams <: GraphParams
    graph_type::Symbol
    λ::Float64
    blocks::Int
    p_in::Float64
    p_out::Float64
    function StochasticBlockModelParams(λ::Real, blocks::Int, p_in::Float64, p_out::Float64)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert blocks >= 1 "'blocks' parameter must be a positive integer"
        @assert 0.0 <= p_in <= 1.0 "'p_in' parameter must be between 0.0 and 1.0"
        @assert 0.0 <= p_in <= 1.0 "'p_out' parameter must be between 0.0 and 1.0"
        return new(:sbm, λ, blocks, p_in, p_out)
    end
    function StochasticBlockModelParams(::Symbol, λ::Real, blocks::Int, p_in::Float64, p_out::Float64)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert blocks >= 1 "'blocks' parameter must be a positive integer"
        @assert 0.0 <= p_in <= 1.0 "'p_in' parameter must be between 0.0 and 1.0"
        @assert 0.0 <= p_in <= 1.0 "'p_out' parameter must be between 0.0 and 1.0"
        return new(:sbm, λ, blocks, p_in, p_out)
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

Get the mean degree of an ErdosRenyiParams instance.
"""
λ(erdos_renyi_params::ErdosRenyiParams) = getfield(erdos_renyi_params, :λ)

"""
    λ(small_world_params:SmallWorldParams)

Get the mean degree of a SmallWorldParams instance.
"""
λ(small_world_params::SmallWorldParams) = getfield(small_world_params, :λ)

"""
    β(small_world_params:SmallWorldParams)

Get the rewiring probability of a SmallWorldParams instance.
"""
β(small_world_params::SmallWorldParams) = getfield(small_world_params, :β)

"""
    λ(scale_free_params:ScaleFreeParams)

Get the mean degree of a ScaleFreeParams instance.
"""
λ(scale_free_params::ScaleFreeParams) = getfield(scale_free_params, :λ)

"""
    α(scale_free_params:ScaleFreeParams)

Get the expected power law degree distribution exponent of a ScaleFreeParams instance.
"""
α(scale_free_params::ScaleFreeParams) = getfield(scale_free_params, :α)

"""
    λ(stochastic_block_model_params:StochasticBlockModelParams)

Get the mean degree of a StochasticBlockModelParams instance.
"""
λ(stochastic_block_model_params::StochasticBlockModelParams) = getfield(stochastic_block_model_params, :λ)

"""
    blocks(stochastic_block_model_params:StochasticBlockModelParams)

Get the number of blocks defined for a StochasticBlockModelParams instance.
"""
blocks(stochastic_block_model_params::StochasticBlockModelParams) = getfield(stochastic_block_model_params, :blocks)

"""
    p_in(stochastic_block_model_params:StochasticBlockModelParams)

Get the in-block edge probability of a StochasticBlockModelParams instance.
"""
p_in(stochastic_block_model_params::StochasticBlockModelParams) = getfield(stochastic_block_model_params, :p_in)

"""
    p_out(stochastic_block_model_params:StochasticBlockModelParams)

Get the out-block edge probability of a StochasticBlockModelParams instance.
"""
p_out(stochastic_block_model_params::StochasticBlockModelParams) = getfield(stochastic_block_model_params, :p_out)


"""
    displayname(graph_params::GraphParams)

Get the string used for displaying a GraphParams instance.
"""
displayname(::CompleteParams) = "Complete"
displayname(graph_params::ErdosRenyiParams) = "ErdosRenyi λ=$(λ(graph_params))"
displayname(graph_params::SmallWorldParams) = "SmallWorld λ=$(λ(graph_params)) β=$(β(graph_params))"
displayname(graph_params::ScaleFreeParams) = "ScaleFree λ=$(λ(graph_params)) α=$(α(graph_params))"
displayname(graph_params::StochasticBlockModelParams) = "StochasticBlockModel λ=$(λ(graph_params)) blocks=$(blocks(graph_params)) p_in=$(p_in(graph_params)) p_out=$(p_out(graph_params))"

Base.show(graph_params::GraphParams) = println(displayname(graph_params))
