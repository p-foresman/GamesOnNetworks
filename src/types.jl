# using Random, StaticArrays


#constructor for individual agents with relevant fields (mutable to update object later)
const Percept = Int8
const PerceptSequence = Vector{Percept}
const TaggedPercept = Tuple{Symbol, Int8}
const TaggedPerceptSequence = Vector{TaggedPercept}
const Choice = Int8

# abstract type Agent end

mutable struct Agent #could make a TaggedAgent as well to separate tags
    name::String
    # tag::Union{Nothing, Symbol} #NOTE: REMOVE
    is_hermit::Bool
    wealth::Int #is this necessary? #NOTE: REMOVE
    memory::PerceptSequence
    choice::Choice

    function Agent(name::String, wealth::Int, memory::PerceptSequence, choice::Choice) #initialize choice at 0 (representing no choice)
        return new(name, false, wealth, memory, choice)
    end
    function Agent(name::String, is_hermit::Bool)
        return new(name, is_hermit, 0, PerceptSequence([]), Choice(0))
    end
    function Agent(name::String)
        return new(name, false, 0, PerceptSequence([]), Choice(0))
    end
    function Agent()
        return new("", false, 0, PerceptSequence([]), Choice(0))
    end
end


# mutable struct TaggedAgent #could make a TaggedAgent as well to separate tags
#     name::String
#     tag::Union{Nothing, Symbol} #NOTE: REMOVE
#     is_hermit::Bool
#     wealth::Int #is this necessary? #NOTE: REMOVE
#     memory::PerceptSequence
#     choice::Int8

#     function Agent(name::String, wealth::Int, memory::Vector{Tuple{Symbol, Int8}}, tag::Union{Nothing, Symbol} = nothing, choice::Int8 = Int8(0)) #initialize choice at 0 (representing no choice)
#         return new(name, tag, false, wealth, memory, choice)
#     end
#     function Agent(name::String, tag::Union{Nothing, Symbol} = nothing)
#         return new(name, tag, false, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
#     function Agent(name::String, is_hermit::Bool)
#         return new(name, nothing, is_hermit, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
#     function Agent(name::String)
#         return new(name, nothing, false, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
#     function Agent()
#         return new("", nothing, false, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
# end


#constructor for specific game to be played
const PayoffMatrix{S1, S2, L} = SMatrix{S1, S2, Tuple{Int8, Int8}, L}
const StrategySet{L} = SVector{L, Int8}

struct Game{S1, S2, L}
    name::String
    payoff_matrix::PayoffMatrix{S1, S2, L} #want to make this parametric (for any int size to be used) #NEED TO MAKE THE SMATRIX SIZE PARAMETRIC AS WELL? Normal Matrix{Tuple{Int8, Int8}} doesnt work with JSON3.read()
    strategies::Tuple{StrategySet{S1}, StrategySet{S2}}                #NEED TO MAKE PLAYER 1 STRATEGIES AND PLAYER 2 STRATEGIES TO ACCOUNT FOR VARYING SIZED PAYOFF MATRICES #NOTE: REMOVE THIS (strategies are inherent in payoff_matrix)

    function Game{S1, S2}(name::String, payoff_matrix::Matrix{Tuple{Int8, Int8}}) where {S1, S2}
        L = S1 * S2
        static_payoff_matrix = SMatrix{S1, S2, Tuple{Int8, Int8}, L}(payoff_matrix)
        strategies = (Tuple(Int8(n) for n in 1:S1), Tuple(Int8(n) for n in 1:S2))
        return new{S1, S2, L}(name, static_payoff_matrix, strategies)
    end
    function Game(name::String, payoff_matrix::Matrix{Tuple{Int8, Int8}})
        matrix_size = size(payoff_matrix)
        S1 = matrix_size[1]
        S2 = matrix_size[2]
        L = S1 * S2
        static_payoff_matrix = SMatrix{S1, S2, Tuple{Int8, Int8}, L}(payoff_matrix)
        strategies = (Tuple(Int8(n) for n in 1:S1), Tuple(Int8(n) for n in 1:S2)) #create integer strategies that correspond to row/column indices of payoff_matrix
        return new{S1, S2, L}(name, static_payoff_matrix, strategies)
    end
    function Game(name::String, payoff_matrix::Matrix{Int8}) #for a zero-sum payoff matrix ########################## MUST FIX THIS!!!!!!!! #####################
        matrix_size = size(payoff_matrix) #need to check size of each dimension bc payoff matrices don't have to be perfect squares
        S1 = matrix_size[1]
        S2 = matrix_size[2]
        L = S1 * S2
        strategies = (Tuple(Int8(n) for n in 1:S1), Tuple(Int8(n) for n in 1:S2)) #create integer strategies that correspond to row/column indices of payoff_matrix
        indices = CartesianIndices(payoff_matrix)
        tuple_vector = Vector{Tuple{Int8, Int8}}([])
        for index in indices
            new_tuple = Tuple{Int8, Int8}([payoff_matrix[index], -payoff_matrix[index]])
            push!(tuple_vector, new_tuple)
        end
        new_payoff_matrix = reshape(tuple_vector, matrix_size)
        return new{S1, S2, L}(name, new_payoff_matrix, strategies)
    end
    function Game{S1, S2, L}(name::String, payoff_matrix::SMatrix{S1, S2, Tuple{Int8, Int8}}, strategies::Tuple{SVector{S1, Int8}, SVector{S2, Int8}}) where {S1, S2, L} ##this method needed for reconstructing with JSON3
        return new{S1, S2, L}(name, payoff_matrix, strategies)
    end
end



struct SimParams
    number_agents::Int64
    memory_length::Int64
    error::Float64
    matches_per_period::Int64
    tags::Union{Nothing, Tuple{Symbol, Symbol, Float64}}
    # tag1::Symbol #could make tags a vararg to have any given number of tags #NOTE: REMOVE
    # tag2::Symbol #NOTE: REMOVE
    # tag1_proportion::Float64 #NOTE: REMOVE
    random_seed::Int64 #probably don't need a random seed in every SimParams struct

    #all keyword arguments
    # function SimParams(number_agents::Int64, memory_length::Int64, error::Float64; tag1::Symbol, tag2::Symbol, tag1_proportion::Float64, random_seed::Int64)
    #     matches_per_period = floor(number_agents / 2)
    #     # sufficient_equity = (1 - error) * memory_length
    #     return new(number_agents, memory_length, error, matches_per_period, tag1, tag2, tag1_proportion, random_seed)
    # end
    function SimParams(number_agents::Int64, memory_length::Int64, error::Float64; tags::Union{Nothing, NamedTuple{(:tag1, :tag2, :tag1_proportion), Tuple{Symbol, Symbol, Float64}}} = nothing, random_seed::Union{Nothing, Int64} = nothing)
        if random_seed === nothing random_seed = 1234 end
        matches_per_period = floor(number_agents / 2)
        # sufficient_equity = (1 - error) * memory_length
        return new(number_agents, memory_length, error, matches_per_period, tags, random_seed)
    end
    function SimParams()
        return new()
    end
end

function displayName(sim_params::SimParams) return "N=$(sim_params.number_agents) m=$(sim_params.memory_length) e=$(sim_params.error)" end


abstract type InteractionParams end

abstract type GraphParams <: InteractionParams end #for static interaction models


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
    dimensions::Int64
    dim_lengths::Vector{Int64}
    function LatticeParams(dim_lengths::Vector{Int64})
        return new(:lattice, length(dim_lengths), dim_lengths)
    end
end
    


# methods to return displayable names as strings for graph types, etc. (similar to .__str__() in Python)
function displayName(::CompleteParams) return "Complete" end
function displayName(graph_params::ErdosRenyiParams) return "ErdosRenyi λ=$(graph_params.λ)" end
function displayName(graph_params::SmallWorldParams) return "SmallWorld κ=$(graph_params.κ) β=$(graph_params.β)" end
function displayName(graph_params::ScaleFreeParams) return "ScaleFree α=$(graph_params.α)" end
function displayName(graph_params::StochasticBlockModelParams) return "StochasticBlockModel communities=$(graph_params.communities) internal_λ=$(graph_params.internal_λ) external_λ=$(graph_params.external_λ)" end


const Graph = SimpleGraph{Int64}
const AgentSet{N} = SVector{N, Agent}
const Relationship = Graphs.SimpleEdge{Int64}
const RelationshipSet{E} = SVector{E, Relationship}
struct AgentGraph{N, E} #a simpler replacement for MetaGraphs
    graph::Graph
    agents::AgentSet{N}
    edges::RelationshipSet{E}
    # number_agents::Int64
    number_hermits::Int64
    
    function AgentGraph(graph::SimpleGraph{Int64})
        N = nv(graph)
        E = ne(graph)
        agents::SVector{N, Agent} = [Agent("Agent $agent_number") for agent_number in 1:N]
        number_hermits = 0
        for vertex in 1:N #could make graph-type specific multiple dispatch so this only needs to happen for ER and SBM (otherwise num_hermits=0)
            if degree(graph, vertex) == 0
                agents[vertex].is_hermit = true
                number_hermits += 1
            end
        end
        graph_edges = SVector{E, Graphs.SimpleEdge{Int64}}(collect(edges(graph)))
        return new{N, E}(graph, agents, graph_edges, number_hermits)
    end
end


# function resetAgentGraph!(agent_graph::AgentGraph)
#     for agent in agent_graph.agents
#         resetAgent!(agent)
#     end
#     return nothing
# end




struct PreAllocatedArrays #{N} #N is number of players (optimize for 2?) #NOTE: should i store these with invividual agents???
    players::Vector{Agent}
    opponent_strategy_recollection::SVector{2, Vector{Int64}}
    opponent_strategy_probs::SVector{2, Vector{Float64}}
    player_expected_utilities::SVector{2, Vector{Float32}}

    function PreAllocatedArrays(payoff_matrix)
        sizes = size(payoff_matrix)
        N = length(sizes)
        players = Vector{Agent}([Agent() for _ in 1:N]) #should always be 2
        opponent_strategy_recollection = SVector{N, Vector{Int64}}(zeros.(Int64, sizes))
        opponent_strategy_probs = SVector{N, Vector{Float64}}(zeros.(Float64, sizes))
        player_expected_utilities = SVector{N, Vector{Float32}}(zeros.(Float32, sizes))
        return new(players, opponent_strategy_recollection, opponent_strategy_probs, player_expected_utilities)
    end
end

function resetArrays!(pre_allocated_arrays::PreAllocatedArrays)
    for player in 1:2
        # pre_allocated_arrays.players[player] = nothing
        pre_allocated_arrays.opponent_strategy_recollection[player] .= Int64(0)
        pre_allocated_arrays.opponent_strategy_probs[player] .= Float64(0)
        pre_allocated_arrays.player_expected_utilities[player] .= Float32(0)
    end
    return nothing
end


abstract type StartingCondition end

struct FractiousState <: StartingCondition
    name::String
    # game::Game

    function FractiousState()
        return new("fractious")
    end
end

struct EquityState <: StartingCondition
    name::String
    # game::Game

    function EquityState()
        return new("equity")
    end
end

struct RandomState <: StartingCondition
    name::String
    # game::Game

    function RandomState()
        return new("random")
    end
end



abstract type StoppingCondition end

mutable struct EquityPsychological <: StoppingCondition
    name::String
    # game::Game
    strategy::Int8
    sufficient_equity::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?) #NOTE: REMOVE
    sufficient_transitioned::Float64


    function EquityPsychological(strategy::Integer)
        return new("equity_psychological", Int8(strategy), 0.0, 0.0)
    end
end

mutable struct EquityBehavioral <: StoppingCondition
    name::String
    # game::Game
    strategy::Int8
    sufficient_transitioned::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?) #NOTE: REMOVE
    # agent_threshold::Union{Nothing, Float64} #initialized to nothing (determine in simulation). DEFENITION: (1-error)*number_agents
    period_cutoff::Int64 #initialized to nothing (determine in simulation). DEFENITION: memory_length.
    period_count::Int64 #initialized at 0
    

    function EquityBehavioral(strategy::Integer)
        return new("equity_behavioral", Int8(strategy), 0.0, 0, 0)
    end
end

struct PeriodCutoff <: StoppingCondition
    name::String
    period_cutoff::Int128

    function PeriodCutoff(period_cutoff::Integer)
        return new("period_cutoff", period_cutoff)
    end
end



##### include functions for model initialization
include("model_functions.jl")

struct SimModel{S1, S2, L, N, E}
    id::Union{Nothing, Int64}
    game::Game{S1, S2, L}
    sim_params::SimParams
    graph_params::GraphParams
    starting_condition::StartingCondition
    stopping_condition::StoppingCondition
    agent_graph::AgentGraph{N, E}
    pre_allocated_arrays::PreAllocatedArrays

    function SimModel(game::Game{S1, S2, L}, sim_params::SimParams, graph_params::GraphParams, starting_condition::StartingCondition, stopping_condition::StoppingCondition, id::Union{Nothing, Int64} = nothing) where {S1, S2, L}
        agent_graph = initGraph(graph_params, game, sim_params, starting_condition)
        N = nv(agent_graph.graph)
        E = ne(agent_graph.graph)
        initStoppingCondition!(stopping_condition, sim_params, agent_graph)
        pre_allocated_arrays = PreAllocatedArrays(game.payoff_matrix)
        return new{S1, S2, L, N, E}(id, game, sim_params, graph_params, starting_condition, stopping_condition, agent_graph, pre_allocated_arrays)
    end
end

function resetModel!(model::SimModel) #NOTE: THIS DOESNT WORK BECAUSE OF IMMUTABLE STRUCT (could work within individual fields)
    resetAgentGraph!(model.agent_graph, model.game, model.sim_params, model.starting_condition)
    initStoppingCondition!(model.stopping_condition, model.sim_params, model.agent_graph)
    resetArrays!(model.pre_allocated_arrays)
end


function resetArrays!(model::SimModel)
    resetArrays!(model.pre_allocated_arrays)
    return nothing
end



#include the global definitions for StructTypes (more global definitions can be added in the file)
include("settings/global_StructTypes.jl")