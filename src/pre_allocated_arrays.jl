struct PreAllocatedArrays #{N} #N is number of players (optimize for 2?) #NOTE: should i store these with invividual agents??? Could call this GameState?
    players::Vector{Agent}
    opponent_strategy_recollection::SVector{2, Vector{Int}}
    opponent_strategy_probs::SVector{2, Vector{Float64}}
    player_expected_utilities::SVector{2, Vector{Float32}}

    function PreAllocatedArrays(payoff_matrix)
        sizes = size(payoff_matrix)
        N = length(sizes)
        players = Vector{Agent}([Agent() for _ in 1:N]) #should always be 2
        opponent_strategy_recollection = SVector{N, Vector{Int}}(zeros.(Int, sizes))
        opponent_strategy_probs = SVector{N, Vector{Float64}}(zeros.(Float64, sizes))
        player_expected_utilities = SVector{N, Vector{Float32}}(zeros.(Float32, sizes))
        return new(players, opponent_strategy_recollection, opponent_strategy_probs, player_expected_utilities)
    end
end

"""
Accessors
"""
players(pre_allocated_arrays::PreAllocatedArrays) = pre_allocated_arrays.players
player(pre_allocated_arrays::PreAllocatedArrays, player_number::Integer) = players(pre_allocated_arrays)[player_number]
opponent_strategy_recollections(pre_allocated_arrays::PreAllocatedArrays) = pre_allocated_arrays.opponent_strategy_recollection
opponent_strategy_recollection(pre_allocated_arrays::PreAllocatedArrays, player_number::Integer) = opponent_strategy_recollections(pre_allocated_arrays)[player_number]
opponent_strategy_recollection(pre_allocated_arrays::PreAllocatedArrays, player_number::Integer, index::Integer) = opponent_strategy_recollection(pre_allocated_arrays, player_number)[index]

function opponent_strategy_recollection!(pre_allocated_arrays::PreAllocatedArrays, player_number::Integer, index::Integer, value::Int)
    opponent_strategy_recollection(pre_allocated_arrays, player_number)[index] = value
end
opponent_strategy_probs(pre_allocated_arrays::PreAllocatedArrays) = pre_allocated_arrays.opponent_strategy_probs
opponent_strategy_probabilities(pre_allocated_arrays::PreAllocatedArrays, player_number::Integer) = opponent_strategy_probs(pre_allocated_arrays)[player_number]
opponent_strategy_probability(pre_allocated_arrays::PreAllocatedArrays, player_number::Integer, index::Integer) = opponent_strategy_probabilities(pre_allocated_arrays, player_number)[index]
player_expected_utilities(pre_allocated_arrays::PreAllocatedArrays) = pre_allocated_arrays.player_expected_utilities
expected_utilities(pre_allocated_arrays::PreAllocatedArrays, player_number::Integer) = player_expected_utilities(pre_allocated_arrays)[player_number]
expected_utility(pre_allocated_arrays::PreAllocatedArrays, player_number::Integer, index::Integer) = expected_utilities(pre_allocated_arrays, player_number)[index]

"""
Mutating Functions
"""
function player!(pre_allocated_arrays::PreAllocatedArrays, player_number::Integer, agent::Agent)
    players(pre_allocated_arrays)[player_number] = agent
    return nothing
end
function reset_arrays!(pre_allocated_arrays::PreAllocatedArrays)
    for player in 1:2
        # pre_allocated_arrays.players[player] = nothing
        pre_allocated_arrays.opponent_strategy_recollection[player] .= Int(0)
        pre_allocated_arrays.opponent_strategy_probs[player] .= Float64(0)
        pre_allocated_arrays.player_expected_utilities[player] .= Float32(0)
    end
    return nothing
end