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