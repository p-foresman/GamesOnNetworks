"""
    InteractionModel

An abstract type representing all interaction parameter types.
"""
abstract type InteractionModel end

"""
    GraphModel

An abstract type representing the class of graph interaction parameters.
"""
abstract type GraphModel <: InteractionModel end #for static interaction models, abm interaction models will come next


"""
    CompleteModel

Type to define and store graph interaction parameters for a complete graph.
"""
struct CompleteModel <: GraphModel
    type::String #type needed for JSON reconstruction
    function CompleteModel()
        return new("CompleteModel")
    end
    function CompleteModel(::String)
        return new("CompleteModel")
    end
end #no constraining parameters


"""
    ErdosRenyiModel

Type to define and store graph interaction parameters for an Erdos-Renyi random graph.
"""
struct ErdosRenyiModel <: GraphModel
    type::String
    λ::Float64
    function ErdosRenyiModel(λ::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        return new("ErdosRenyiModel", Float64(λ))
    end
    function ErdosRenyiModel(::String, λ::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        return new("ErdosRenyiModel", Float64(λ))
    end
end

"""
    SmallWorldModel

Type to define and store graph interaction parameters for a small-world (Watts-Strogatz) random graph.
"""
struct SmallWorldModel <: GraphModel
    type::String
    λ::Float64
    β::Float64
    function SmallWorldModel(λ::Real, β::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert 0.0 <= β <= 1.0 "'β' parameter must be between 0.0 and 1.0"
        return new("SmallWorldModel", Float64(λ), Float64(β))
    end
    function SmallWorldModel(::String, λ::Real, β::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert 0.0 <= β <= 1.0 "'β' parameter must be between 0.0 and 1.0"
        return new("SmallWorldModel", Float64(λ), Float64(β))
    end
end

"""
    ScaleFreeModel

Type to define and store graph interaction parameters for a scale-free random graph.
"""
struct ScaleFreeModel <: GraphModel
    type::String
    λ::Float64
    α::Float64
    function ScaleFreeModel(λ::Real, α::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert α >= 2 "'α' parameter must be >= 2.0"
        return new("ScaleFreeModel", Float64(λ), Float64(α))
    end
    function ScaleFreeModel(::String, λ::Real, α::Real)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert α >= 2 "'α' parameter must be >= 2.0"
        return new("ScaleFreeModel", Float64(λ), Float64(α))
    end
end

"""
    StochasticBlockModel

Type to define and store graph interaction parameters for a stochastic block model random graph.
"""
struct StochasticBlockModel <: GraphModel
    type::String
    λ::Float64
    blocks::Int
    p_in::Float64
    p_out::Float64
    function StochasticBlockModel(λ::Real, blocks::Int, p_in::Float64, p_out::Float64)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert blocks >= 1 "'blocks' parameter must be a positive integer"
        @assert 0.0 <= p_in <= 1.0 "'p_in' parameter must be between 0.0 and 1.0"
        @assert 0.0 <= p_in <= 1.0 "'p_out' parameter must be between 0.0 and 1.0"
        return new("StochasticBlockModel", λ, blocks, p_in, p_out)
    end
    function StochasticBlockModel(::String, λ::Real, blocks::Int, p_in::Float64, p_out::Float64)
        @assert λ >= 1 "'λ' parameter must be >= 1.0"
        @assert blocks >= 1 "'blocks' parameter must be a positive integer"
        @assert 0.0 <= p_in <= 1.0 "'p_in' parameter must be between 0.0 and 1.0"
        @assert 0.0 <= p_in <= 1.0 "'p_out' parameter must be between 0.0 and 1.0"
        return new("StochasticBlockModel", λ, blocks, p_in, p_out)
    end
end


# struct LatticeModel <: GraphModel
#     graph_type::Symbol
#     dimensions::Int
#     dim_lengths::Vector{Int}
#     function LatticeModel(dim_lengths::Vector{Int})
#         return new(:lattice, length(dim_lengths), dim_lengths)
#     end
# end
    

##########################################
# GraphModel Accessors
##########################################

"""
    type(graphmodel::GraphModel)

Get the type of a GraphModel instance in a string.
"""
type(graphmodel::GraphModel) = getfield(graphmodel, :type)
# type(::GM) where {GM<:GraphModel} = string(GM)


"""
    λ(erdos_renyi_model:ErdosRenyiModel)

Get the mean degree of an ErdosRenyiModel instance.
"""
λ(erdos_renyi_model::ErdosRenyiModel) = getfield(erdos_renyi_model, :λ)

"""
    λ(small_world_model:SmallWorldModel)

Get the mean degree of a SmallWorldModel instance.
"""
λ(small_world_model::SmallWorldModel) = getfield(small_world_model, :λ)

"""
    β(small_world_model:SmallWorldModel)

Get the rewiring probability of a SmallWorldModel instance.
"""
β(small_world_model::SmallWorldModel) = getfield(small_world_model, :β)

"""
    λ(scale_free_model:ScaleFreeModel)

Get the mean degree of a ScaleFreeModel instance.
"""
λ(scale_free_model::ScaleFreeModel) = getfield(scale_free_model, :λ)

"""
    α(scale_free_model:ScaleFreeModel)

Get the expected power law degree distribution exponent of a ScaleFreeModel instance.
"""
α(scale_free_model::ScaleFreeModel) = getfield(scale_free_model, :α)

"""
    λ(stochastic_block_model:StochasticBlockModel)

Get the mean degree of a StochasticBlockModel instance.
"""
λ(stochastic_block_model::StochasticBlockModel) = getfield(stochastic_block_model, :λ)

"""
    blocks(stochastic_block_model:StochasticBlockModel)

Get the number of blocks defined for a StochasticBlockModel instance.
"""
blocks(stochastic_block_model::StochasticBlockModel) = getfield(stochastic_block_model, :blocks)

"""
    p_in(stochastic_block_model:StochasticBlockModel)

Get the in-block edge probability of a StochasticBlockModel instance.
"""
p_in(stochastic_block_model::StochasticBlockModel) = getfield(stochastic_block_model, :p_in)

"""
    p_out(stochastic_block_model:StochasticBlockModel)

Get the out-block edge probability of a StochasticBlockModel instance.
"""
p_out(stochastic_block_model::StochasticBlockModel) = getfield(stochastic_block_model, :p_out)


"""
    displayname(graphmodel::GraphModel)

Get the string used for displaying a GraphModel instance.
"""
displayname(::CompleteModel) = "Complete"
displayname(graphmodel::ErdosRenyiModel) = "ErdosRenyi λ=$(λ(graphmodel))"
displayname(graphmodel::SmallWorldModel) = "SmallWorld λ=$(λ(graphmodel)) β=$(β(graphmodel))"
displayname(graphmodel::ScaleFreeModel) = "ScaleFree λ=$(λ(graphmodel)) α=$(α(graphmodel))"
displayname(graphmodel::StochasticBlockModel) = "StochasticBlockModel λ=$(λ(graphmodel)) blocks=$(blocks(graphmodel)) p_in=$(p_in(graphmodel)) p_out=$(p_out(graphmodel))"

Base.show(graphmodel::GraphModel) = println(displayname(graphmodel))



# Graph Generators (maybe not the best place to put them)

function generate_graph(::CompleteModel, simparams::SimParams)
    graph::Graphs.SimpleGraphs.SimpleGraph{Int} = complete_graph(number_agents(simparams))
    return graph
end

function generate_graph(graphmodel::ErdosRenyiModel, simparams::SimParams)
    graph::Graphs.SimpleGraphs.SimpleGraph{Int} = erdos_renyi_rg(number_agents(simparams), λ(graphmodel))
    if ne(graph) == 0 #NOTE: we aren't considering graphs with no edges (obviously). Does it even make sense to consider graphs with more than one component?
        return generate_graph(graphmodel, simparams)
    end
    return graph
end

function generate_graph(graphmodel::SmallWorldModel, simparams::SimParams)
    graph::Graphs.SimpleGraphs.SimpleGraph{Int} = small_world_rg(number_agents(simparams), λ(graphmodel), β(graphmodel))
    if ne(graph) == 0 #NOTE: we aren't considering graphs with no edges (obviously). Does it even make sense to consider graphs with more than one component?
        return generate_graph(graphmodel, simparams)
    end
    return graph
end

function generate_graph(graphmodel::ScaleFreeModel, simparams::SimParams)
    graph::Graphs.SimpleGraphs.SimpleGraph{Int} = scale_free_rg(number_agents(simparams), λ(graphmodel), α(graphmodel))
    if ne(graph) == 0 #NOTE: we aren't considering graphs with no edges (obviously). Does it even make sense to consider graphs with more than one component?
        return generate_graph(graphmodel, simparams)
    end
    return graph
end

function generate_graph(graphmodel::StochasticBlockModel, simparams::SimParams)
    @assert number_agents(simparams) % blocks(graphmodel) == 0 "Number of blocks must divide population evenly"
    block_size = Int(number_agents(simparams) / blocks(graphmodel))
    p_in_vector = Vector{Float64}([])
    block_sizes_vector = Vector{Int}([])
    for _ in 1:blocks(graphmodel)
        push!(p_in_vector, p_in(graphmodel))
        push!(block_sizes_vector, block_size)
    end
    graph::Graphs.SimpleGraphs.SimpleGraph{Int} = stochastic_block_model_rg(block_sizes_vector, λ(graphmodel), p_in_vector, p_out(graphmodel))
    if ne(graph) == 0 #NOTE: we aren't considering graphs with no edges (obviously). Does it even make sense to consider graphs with more than one component?
        return generate_graph(graphmodel, simparams)
    end
    return graph
end
