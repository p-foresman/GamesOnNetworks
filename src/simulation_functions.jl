
############################### FUNCTIONS #######################################



######################## game algorithm ####################


#play the defined game
function playGame!(model::SimModel)
    # @timeit to "make choices" makeChoices!(model)
    # @timeit to "update memories" updateMemories!(model.pre_allocated_arrays.players, model.sim_params)
    makeChoices!(model)
    updateMemories!(model)
    return nothing
end

function runPeriod!(model::SimModel) #NOTE: what type are graph_edges ??
    for match in 1:model.sim_params.matches_per_period
        # @timeit to "match" begin
        # @timeit to "set players" setPlayers!(model)
        # @timeit to "reset arrays" resetArrays!(model)
        # @timeit to "set players" setPlayers!(model)
        # #println(players[1].name * " playing game with " * players[2].name)
        # @timeit to "play game" playGame!(model, to)
        resetArrays!(model)
        setPlayers!(model)
        #println(players[1].name * " playing game with " * players[2].name)
        playGame!(model)
        # end
    end
    return nothing
end

# function findOpponentStrategyProbs!(model::SimModel)
#     findOpponentStrategyProbs!(model.pre_allocated_arrays.opponent_strategy_recollection, model.pre_allocated_arrays.opponent_strategy_probs, model.pre_allocated_arrays.players)
#     return nothing
# end

# function findExpectedUtilities!(model::SimModel)
#     findExpectedUtilities!(model.pre_allocated_arrays.player_expected_utilities, model.game.payoff_matrix, model.pre_allocated_arrays.opponent_strategy_probs)
#     return nothing
# end


#choice algorithm for agents "deciding" on strategies (find max expected payoff)
function makeChoices!(model::SimModel) #COULD LIKELY MAKE THIS FUNCTION BETTER. Could use CartesianIndices() to iterate through payoff matrix? 
    # player_choices::Vector{Int8} = [rand(game.strategies[1]), rand(game.strategies[2])]
    
    #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
    #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
    #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.

    findOpponentStrategyProbs!(model)
    findExpectedUtilities!(model)
    # print("player_expected_utilities: ")
    # println(player_expected_utilities)
    
    # for player in 1:2 #eachindex(model.pre_allocated_arrays.players)
    #     if rand() <= model.sim_params.error
    #         model.pre_allocated_arrays.players[player].choice = rand(model.game.strategies[player])
    #     else
    #         model.pre_allocated_arrays.players[player].choice = findMaximumStrategy(model.pre_allocated_arrays.player_expected_utilities[player])
    #     end
    # end

    for player in 1:2 #eachindex(model.pre_allocated_arrays.players)
        getPlayer(model, player).rational_choice = findMaximumStrategy(model.pre_allocated_arrays.player_expected_utilities[player])
        getPlayer(model, player).choice = rand() <= model.sim_params.error ? rand(model.game.strategies[player]) : getPlayer(model, player).rational_choice
    end

    # print("player_choices: ")
    # print(players[1].choice)
    # print(", ")
    # println(players[2].choice)
    # println(player_choices)
    return nothing

    # outcome = game.payoff_matrix[player_choices[1], player_choices[2]] #don't need this right now (wealth is not being analyzed)
    # players[1].wealth += outcome[1]
    # players[2].wealth += outcome[2]
end

function setChoices!(model::SimModel)
    for player in 1:2 #eachindex(model.pre_allocated_arrays.players)
        if rand() <= model.sim_params.error 
            model.pre_allocated_arrays.players[player].choice = rand(model.game.strategies[player])
        else
            model.pre_allocated_arrays.players[player].choice = findMaximumStrats(model.pre_allocated_arrays.player_expected_utilities[player])
        end
    end
end


#other player isn't even needed without tags. this could be simplified
function calculateOpponentStrategyProbs!(model::SimModel, player::Int)
    @inbounds for memory in getPlayer(model, player).memory
        getOpponentStrategyRecollection(model, player)[memory] += 1 #memory strategy is simply the payoff_matrix index for the given dimension
    end
    getOpponentStrategyProbs(model, player) .= model.pre_allocated_arrays.opponent_strategy_recollection[player] ./ sum(model.pre_allocated_arrays.opponent_strategy_recollection[player])
    return nothing
end

function findOpponentStrategyProbs!(model::SimModel)
    for player in 1:2
        calculateOpponentStrategyProbs!(model, player)
    end
    return nothing
end

function findExpectedUtilities!(model::SimModel)
    @inbounds for column in axes(model.game.payoff_matrix, 2) #column strategies
        for row in axes(model.game.payoff_matrix, 1) #row strategies
            getPlayerExpectedUtilities(model, 1)[row] += model.game.payoff_matrix[row, column][1] * getOpponentStrategyProbs(model, 1)[column]
            getPlayerExpectedUtilities(model, 2)[column] += model.game.payoff_matrix[row, column][2] * getOpponentStrategyProbs(model, 2)[row]
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



# function findMaximumStrats(expected_utilities::Vector{Float32})
#     max_positions = Vector{Int}()
#     max_val = Float32(0.0)
#     for i in eachindex(expected_utilities)
#         if expected_utilities[i] > max_val
#             max_val = expected_utilities[i]
#             empty!(max_positions)
#             push!(max_positions, i)
#         elseif expected_utilities[i] == max_val
#             push!(max_positions, i)
#         end
#     end
#     return rand(max_positions)
# end

function findMaximumStrategy(expected_utilities::Vector{Float32})
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



# update agent's memory vector
function updateMemory!(agent::Agent, percept::Percept, memory_length::Int)
    if length(agent.memory) == memory_length
        popfirst!(agent.memory)
    end
    push!(agent.memory, percept)
    return nothing
end

function updateMemories!(model::SimModel)
    updateMemory!(getPlayer(model, 1), getPlayer(model, 2).choice, model.sim_params.memory_length)
    updateMemory!(getPlayer(model, 2), getPlayer(model, 1).choice, model.sim_params.memory_length)
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

#NOTE: CAN REMOVE SIM_PARAMS FROM THESE! (ALL CALCULATIONS DONE IN MODEL INITIALIZATION)
function checkStoppingCondition(model::SimModel, stopping_condition::EquityPsychological, ::Int128) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    number_transitioned = 0
    for agent in getAgents(model)
        if !agent.is_hermit
            if countStrats(agent.memory, stopping_condition.strategy) >= stopping_condition.sufficient_equity #this is hard coded to strategy 2 (M) for now. Should change later!
                number_transitioned += 1
            end
        end
    end 
    return number_transitioned >= stopping_condition.sufficient_transitioned
end

function checkStoppingCondition(model::SimModel, stopping_condition::EquityBehavioral, ::Int128) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    number_transitioned = 0
    for agent in getAgents(model)
        if !agent.is_hermit
            if agent.rational_choice == stopping_condition.strategy #if the agent is acting in an equitable fashion (if all agents act equitably, we can say that the behavioral equity norm is reached (ideally, there should be some time frame where all or most agents must have acted equitably))
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



function checkStoppingCondition(::SimModel, stopping_condition::PeriodCutoff, current_periods::Int128)
    return current_periods >= stopping_condition.period_cutoff
end




function countStrats(memory_set::PerceptSequence, desired_strat::Int8)
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

