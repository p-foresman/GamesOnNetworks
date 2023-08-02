# using Random, StaticArrays

#constructor for individual agents with relevant fields (mutable to update object later)
mutable struct Agent
    name::String
    tag::Symbol
    wealth::Int #is this necessary?
    memory::Vector{Tuple{Symbol, Int8}}
    choice::Union{Int8, Nothing}

    function Agent(name::String, tag::Symbol, wealth::Int, memory::Vector{Tuple{Symbol, Int8}}, choice::Union{Int8, Nothing} = nothing)
        return new(name, tag, wealth, memory, choice)
    end
    function Agent(name::String, tag::Symbol)
        return new(name, tag, 0, Vector{Tuple{Symbol, Int8}}([]), nothing)
    end
    function Agent(name::String)
        return new(name, Symbol(), 0, Vector{Tuple{Symbol, Int8}}([]), nothing)
    end
    function Agent()
        return new("", Symbol(), 0, Vector{Tuple{Symbol, Int8}}([]), nothing)
    end
end


#constructor for specific game to be played
struct Game{S1, S2, L}
    name::String
    payoff_matrix::SMatrix{S1, S2, Tuple{Int8, Int8}, L} #want to make this parametric (for any int size to be used) #NEED TO MAKE THE SMATRIX SIZE PARAMETRIC AS WELL? Normal Matrix{Tuple{Int8, Int8}} doesnt work with JSON3.read()
    strategies::Tuple{SVector{S1, Int8}, SVector{S2, Int8}}                #NEED TO MAKE PLAYER 1 STRATEGIES AND PLAYER 2 STRATEGIES TO ACCOUNT FOR VARYING SIZED PAYOFF MATRICES

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
    memory_init_state::Symbol
    error::Float64
    matches_per_period::Int64 #defined within constructor
    sufficient_equity::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?)
    tag1::Symbol #could make tags a vararg to have any given number of tags
    tag2::Symbol
    tag1_proportion::Float64
    random_seed::Int64 #probably don't need a random seed in every SimParams struct

    #all keyword arguments
    function SimParams(;number_agents::Int64, memory_length::Int64, memory_init_state::Symbol, error::Float64, tag1::Symbol, tag2::Symbol, tag1_proportion::Float64, random_seed::Int64)
        matches_per_period = floor(number_agents / 2)
        sufficient_equity = (1 - error) * memory_length
        return new(number_agents, memory_length, memory_init_state, error, matches_per_period, sufficient_equity, tag1, tag2, tag1_proportion, random_seed)
    end
    function SimParams()
        return new()
    end
end

function displayName(sim_params::SimParams) return "N=$(sim_params.number_agents) m=$(sim_params.memory_length) e=$(sim_params.error)" end


abstract type InteractionParams end

abstract type GraphParams <: InteractionParams end #for static interaction models

abstract type ABMParams <: InteractionParams end #for mobile interaction models

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


struct GridABMParams <: ABMParams
    x_size::Int
    y_size::Int
end
    


# methods to return displayable names as strings for graph types, etc. (similar to .__str__() in Python)
function displayName(::CompleteParams) return "Complete" end
function displayName(graph_params::ErdosRenyiParams) return "ErdosRenyi λ=$(graph_params.λ)" end
function displayName(graph_params::SmallWorldParams) return "SmallWorld κ=$(graph_params.κ) β=$(graph_params.β)" end
function displayName(graph_params::ScaleFreeParams) return "ScaleFree α=$(graph_params.α)" end
function displayName(graph_params::StochasticBlockModelParams) return "StochasticBlockModel communities=$(graph_params.communities) internal_λ=$(graph_params.internal_λ) external_λ=$(graph_params.external_λ)" end



struct AgentGraph{N} #a simpler replacement for MetaGraphs
    graph::SimpleGraph{Int64}
    agents::SVector{N, Agent}
    
    function AgentGraph{N}(graph::SimpleGraph{Int64}) where {N}
        # N = length(vertices(graph))
        agents::SVector{N, Agent} = [Agent("Agent $agent_number") for agent_number in 1:N]
        return new{N}(graph, agents)
    end
end





struct PreAllocatedArrays{N} #N is number of players
    opponent_strategy_recollection::SVector{N, Vector{Int64}}
    opponent_strategy_probs::SVector{N, Vector{Float64}}
    player_expected_utilities::SVector{N, Vector{Float32}}

    function PreAllocatedArrays(payoff_matrix)
        sizes = size(payoff_matrix)
        N = length(sizes)
        opponent_strategy_recollection = SVector{N, Vector{Int64}}(zeros.(Int64, sizes))
        opponent_strategy_probs = SVector{N, Vector{Float64}}(zeros.(Float64, sizes))
        player_expected_utilities = SVector{N, Vector{Float32}}(zeros.(Float32, sizes))
        return new{N}(opponent_strategy_recollection, opponent_strategy_probs, player_expected_utilities)
    end
end
function resetArrays!(pre_allocated_arrays::PreAllocatedArrays)
    for player in eachindex(pre_allocated_arrays.opponent_strategy_recollection)
        pre_allocated_arrays.opponent_strategy_recollection[player] .= Int64(0)
        pre_allocated_arrays.opponent_strategy_probs[player] .= Float64(0)
        pre_allocated_arrays.player_expected_utilities[player] .= Float32(0)
    end
    return nothing
end


abstract type StartingCondition end

struct FractiousState <: StartingCondition
    name::Symbol
    game::Game

    function FractiousState(game::Game)
        return new(:fractious, game)
    end
end

struct EquityState <: StartingCondition
    name::Symbol
    game::Game

    function EquityState(game::Game)
        return new(:equity, game)
    end
end

struct RandomState <: StartingCondition
    name::Symbol
    game::Game

    function RandomState(game::Game)
        return new(:random, game)
    end
end


abstract type StoppingCondition end

struct EquityPsychological <: StoppingCondition
    name::Symbol
    game::Game
    strategy::Int8

    function EquityPsychological(game::Game, strategy::Integer)
        return new(:equity_psychological, game, Int8(strategy))
    end
end

mutable struct EquityBehavioral <: StoppingCondition
    name::Symbol
    game::Game
    strategy::Int8
    # agent_threshold::Union{Nothing, Float64} #initialized to nothing (determine in simulation). DEFENITION: (1-error)*number_agents
    period_limit::Union{Nothing, Int64} #initialized to nothing (determine in simulation). DEFENITION: memory_length
    period_count::Int64 #initialized at 0
    

    function EquityBehavioral(game::Game, strategy::Integer)
        return new(:equity_behavioral, game, Int8(strategy), nothing, 0)
    end
end

struct PeriodCutoff <: StoppingCondition
    name::Symbol
    period_cutoff::Int128

    function PeriodCutoff(period_cutoff::Integer)
        return new(:period_cutoff, period_cutoff)
    end
end

#include the global definitions for StructTypes (more global definitions can be added in the file)
include("settings/global_StructTypes.jl")