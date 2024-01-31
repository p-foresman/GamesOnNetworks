
############################### FUNCTIONS #######################################



######################## game algorithm ####################


function play_game!(model::SimModel)
    #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
    #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
    #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.
    find_opponent_strategy_probabilities!(model)
    calculate_expected_utilities!(model)
    make_choices!(model)
    push_memories!(model)
    return nothing
end

function run_period!(model::SimModel) #NOTE: what type are graph_edges ??
    for _ in 1:matches_per_period(model)
        reset_arrays!(model)
        players!(model)
        play_game!(model)
    end
    return nothing
end


function make_choices!(model::SimModel)
    for player_number in 1:2 #eachindex(model.pre_allocated_arrays.players)
        rational_choice!(player(model, player_number), Choice(maximum_strategy(expected_utilities(model, player_number))))
        choice!(player(model, player_number), rand() <= error(model) ? random_strategy(model) : rational_choice(player(model, player_number)))
    end
end


#other player isn't even needed without tags. this could be simplified
function calculate_opponent_strategy_probabilities!(model::SimModel, player_number::Integer)
    @inbounds for memory in memory(player(model, player_number))
        opponent_strategy_recollection(model, player_number)[memory] += 1 #memory strategy is simply the payoff_matrix index for the given dimension (use a setter here instead?)
    end
    opponent_strategy_probabilities(model, player_number) .= opponent_strategy_recollection(model, player_number) ./ sum(opponent_strategy_recollection(model, player_number))
    return nothing
end

function find_opponent_strategy_probabilities!(model::SimModel)
    for player_number in 1:2
        calculate_opponent_strategy_probabilities!(model, player_number)
    end
    return nothing
end

function calculate_expected_utilities!(model::SimModel)
    @inbounds for column in axes(payoff_matrix(model), 2) #column strategies
        for row in axes(payoff_matrix(model), 1) #row strategies
            expected_utilities(model, 1)[row] += payoff_matrix(model)[row, column][1] * opponent_strategy_probability(model, 1, column)
            expected_utilities(model, 2)[column] += payoff_matrix(model)[row, column][2] * opponent_strategy_probability(model, 2, row)
        end
    end
    return nothing
end


# with tag functionality
# function calculateOpponentStrategyProbs!(player_memory, opponent_tag, opponent_strategy_recollection, opponent_strategy_probs)
#     @inbounds for memory in player_memory
#         if memory[1] == opponent_tag #if the opponent's tag is not present, no need to count strategies
#             opponent_strategy_recollection[memory[2]] += 1 #memory strategy is simply the payoff_matrix index for the given dimension
#         end
#     end
#     opponent_strategy_probs .= opponent_strategy_recollection ./ sum(opponent_strategy_recollection)
#     return nothing
# end


function maximum_strategy(expected_utilities::Vector{Float32})
    max_positions = Vector{Int}()
    max_val = Float32(0.0)
    for i in eachindex(expected_utilities)
        if expected_utilities[i] > max_val
            max_val = expected_utilities[i]
            empty!(max_positions)
            push!(max_positions, i)
        elseif expected_utilities[i] == max_val
            push!(max_positions, i)
        end
    end
    return rand(max_positions)
end


function push_memory!(agent::Agent, percept::Percept, memory_length::Int) #NOTE: should i memory instead of agent?
    if length(memory(agent)) == memory_length
        popfirst!(memory(agent))
    end
    push!(memory(agent), percept)
    return nothing
end

function push_memories!(model::SimModel)
    push_memory!(player(model, 1), choice(player(model, 2)), memory_length(model))
    push_memory!(player(model, 2), choice(player(model, 1)), memory_length(model))
    return nothing
end




######################## STUFF FOR DETERMINING AGENT BEHAVIOR (should combine this with above functions in the future) ###############################

function calculateExpectedOpponentProbs(::Game{S1, S2, L}, memory_set::PerceptSequence) where {S1, S2, L}
    # length = size(game.payoff_matrix, 1) #for symmetric games only
    opponent_strategy_recollection = zeros(Int, S1)
    for memory in memory_set
        opponent_strategy_recollection[memory] += 1 #memory strategy is simply the payoff_matrix index for the given dimension
    end
    opponent_strategy_probs = opponent_strategy_recollection ./ sum(opponent_strategy_recollection)
    return opponent_strategy_probs
end


function calculateExpectedUtilities(game::Game{S1, S2, L}, opponent_probs) where {S1, S2, L} #for symmetric games only!
    payoff_matrix = game.payoff_matrix
    player_expected_utilities = zeros(Float32, S1)
    @inbounds for column in axes(game.payoff_matrix, 2) #column strategies
        for row in axes(game.payoff_matrix, 1) #row strategies
            player_expected_utilities[row] += payoff_matrix[row, column][1] * opponent_probs[column]
        end
    end
    return player_expected_utilities
end


function determineAgentBehavior(game::Game, memory_set::PerceptSequence)
    opponent_strategy_probs = calculateExpectedOpponentProbs(game, memory_set)
    expected_utilities = calculateExpectedUtilities(game, opponent_strategy_probs)
    max_strat = findMaximumStrategy(expected_utilities) #right now, if more than one strategy results in a max expected utility, a random strategy is chosen of the maximum strategies
    return max_strat
end

########### tagged memory stuff #####
# function calculateExpectedOpponentProbs(::Game{S1, S2, L}, memory_set::PerceptSequence) where {S1, S2, L}
#     # length = size(game.payoff_matrix, 1) #for symmetric games only
#     opponent_strategy_recollection = zeros(Int, S1)
#     for memory in memory_set
#         opponent_strategy_recollection[memory[2]] += 1 #memory strategy is simply the payoff_matrix index for the given dimension
#     end
#     opponent_strategy_probs = opponent_strategy_recollection ./ sum(opponent_strategy_recollection)
#     return opponent_strategy_probs
# end

# function determineAgentBehavior(game::Game, memory_set::Vector{Tuple{Symbol, Int8}})
#     opponent_strategy_probs = calculateExpectedOpponentProbs(game, memory_set)
#     expected_utilities = calculateExpectedUtilities(game, opponent_strategy_probs)
#     max_strat = findMaximumStrats(expected_utilities) #right now, if more than one strategy results in a max expected utility, a random strategy is chosen of the maximum strategies
#     return max_strat
# end

#######################################################

function is_stopping_condition(model::SimModel, stopping_condition::EquityPsychological, ::Int128) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    number_transitioned = 0
    for agent in agents(model)
        if !ishermit(agent)
            if count_strategy(memory(agent), stopping_condition.strategy) >= stopping_condition.sufficient_equity #this is hard coded to strategy 2 (M) for now. Should change later!
                number_transitioned += 1
            end
        end
    end 
    return number_transitioned >= stopping_condition.sufficient_transitioned
end

function is_stopping_condition(model::SimModel, stopping_condition::EquityBehavioral, ::Int128) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    number_transitioned = 0
    for agent in agents(model)
        if !ishermit(agent)
            if rational_choice(agent) == stopping_condition.strategy #if the agent is acting in an equitable fashion (if all agents act equitably, we can say that the behavioral equity norm is reached (ideally, there should be some time frame where all or most agents must have acted equitably))
                number_transitioned += 1
            end
        end
    end 

    if number_transitioned >= stopping_condition.sufficient_transitioned
        stopping_condition.period_count += 1
        return stopping_condition.period_count >= stopping_condition.period_cutoff
    else
        stopping_condition.period_count = 0 #reset period count
        return false
    end
end



function is_stopping_condition(::SimModel, stopping_condition::PeriodCutoff, current_periods::Int128)
    return current_periods >= stopping_condition.period_cutoff
end




function count_strategy(memory_set::PerceptSequence, desired_strat::Int8)
    count::Int = 0
    for memory in memory_set
        if memory == desired_strat
            count += 1
        end
    end
    return count
end

#tagged functionality
# function countStrats(memory_set::Vector{Tuple{Symbol, Int8}}, desired_strat)
#     count::Int = 0
#     for memory in memory_set
#         if memory[2] == desired_strat
#             count += 1
#         end
#     end
#     return count
# end

