
############################### FUNCTIONS #######################################



######################## game algorithm ####################


function setPlayers!(model::SimModel)
    edge::Graphs.SimpleEdge{Int64} = rand(model.agent_graph.edges)
    vertex_list::Vector{Int64} = shuffle!([edge.src, edge.dst])
    for player in 1:2 #NOTE: this will always be 2. Should I just optimize for two player games?
        model.pre_allocated_arrays.players[player] = model.agent_graph.agents[vertex_list[player]]
    end
    return nothing
end


function updateMemories!(model::SimModel)
    updateMemories!(model.pre_allocated_arrays.players, model.sim_params)
    return nothing
end

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
    
    for player in 1:2 #eachindex(model.pre_allocated_arrays.players)
        # if rand() <= model.sim_params.error
        #     model.pre_allocated_arrays.players[player].choice = rand(model.game.strategies[player])
        # else
            # model.pre_allocated_arrays.players[player].choice = findMaximumStrats(model.pre_allocated_arrays.player_expected_utilities[player])
            chooseMaximumStrat!(model, player)

        # end
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

# function decide!(model::SimModel)
#     for player in 1:2 #eachindex(model.pre_allocated_arrays.players)
#         if rand() <= model.sim_params.error 
#             model.pre_allocated_arrays.players[player].choice = rand(model.game.strategies[player])
#         else
#             model.pre_allocated_arrays.players[player].choice = findMaximumStrats(model.pre_allocated_arrays.player_expected_utilities[player])
#         end
#     end
# end


#other player isn't even needed without tags. this could be simplified
function calculateOpponentStrategyProbs!(model::SimModel, player::Int)
    @inbounds for memory in model.pre_allocated_arrays.players[player].memory
        model.pre_allocated_arrays.opponent_strategy_recollection[player][memory] += 1 #memory strategy is simply the payoff_matrix index for the given dimension
    end
    model.pre_allocated_arrays.opponent_strategy_probs[player] .= model.pre_allocated_arrays.opponent_strategy_recollection[player] ./ sum(model.pre_allocated_arrays.opponent_strategy_recollection[player])
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
            model.pre_allocated_arrays.player_expected_utilities[1][row] += model.game.payoff_matrix[row, column][1] * model.pre_allocated_arrays.opponent_strategy_probs[1][column]
            model.pre_allocated_arrays.player_expected_utilities[2][column] += model.game.payoff_matrix[row, column][2] * model.pre_allocated_arrays.opponent_strategy_probs[2][row]
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

function chooseMaximumStrat!(model::SimModel, player::Int)
    max_positions = Vector{Int}()
    max_val = Float32(0.0)
    for i in eachindex(model.pre_allocated_arrays.player_expected_utilities[player])
        if model.pre_allocated_arrays.player_expected_utilities[player][i] > max_val
            max_val = model.pre_allocated_arrays.player_expected_utilities[player][i]
            empty!(max_positions)
            push!(max_positions, i)
        elseif model.pre_allocated_arrays.player_expected_utilities[player][i] == max_val
            push!(max_positions, i)
        end
    end
    model.pre_allocated_arrays.players[player].choice = rand(max_positions)
    return nothing
end



# update agent's memory vector
function pushMemory!(agent::Agent, percept::Percept, sim_params::SimParams)
    if length(agent.memory) == sim_params.memory_length
        popfirst!(agent.memory)
    end
    push!(agent.memory, percept)
    return nothing
end

# function pushMemory!(model::SimModel, player::Int, opponent::Int)
#     if length(model.pre_allocated_arrays.players[player].memory) == model.sim_params.memory_length
#         popfirst!(model.pre_allocated_arrays.players[player].memory)
#     end
#     push!(model.pre_allocated_arrays.players[player].memory, model.pre_allocated_arrays.players[opponent].choice)
#     return nothing
# end

function updateMemories!(players::Vector{Agent}, sim_params::SimParams)
    pushMemory!(players[1], players[2].choice, sim_params)
    pushMemory!(players[2], players[1].choice, sim_params)
    return nothing
end

# function updateMemories!(model::SimModel)
#     pushMemory!(model, 1, 2)
#     pushMemory!(model, 2, 1)
#     return nothing
# end




######################## STUFF FOR DETERMINING AGENT BEHAVIOR (should combine this with above functions in the future) ###############################

function calculateExpectedOpponentProbs(::Game{S1, S2, L}, memory_set::PerceptSequence) where {S1, S2, L}
    # length = size(game.payoff_matrix, 1) #for symmetric games only
    opponent_strategy_recollection = zeros(Int64, S1)
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
    max_strat = findMaximumStrats(expected_utilities) #right now, if more than one strategy results in a max expected utility, a random strategy is chosen of the maximum strategies
    return max_strat
end

########### tagged memory stuff #####
# function calculateExpectedOpponentProbs(::Game{S1, S2, L}, memory_set::PerceptSequence) where {S1, S2, L}
#     # length = size(game.payoff_matrix, 1) #for symmetric games only
#     opponent_strategy_recollection = zeros(Int64, S1)
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
function checkStoppingCondition(::Game, stopping_condition::EquityPsychological, agent_graph::AgentGraph, ::Int128) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    number_transitioned = 0
    for agent in agent_graph.agents
        if !agent.is_hermit
            if countStrats(agent.memory, stopping_condition.strategy) >= stopping_condition.sufficient_equity #this is hard coded to strategy 2 (M) for now. Should change later!
                number_transitioned += 1
            end
        end
    end 
    return number_transitioned >= stopping_condition.sufficient_transitioned
end

function checkStoppingCondition(game::Game, stopping_condition::EquityBehavioral, agent_graph::AgentGraph, ::Int128) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    number_transitioned = 0
    for agent in agent_graph.agents
        if !agent.is_hermit
            if determineAgentBehavior(game, agent.memory) == stopping_condition.strategy #if the agent is acting in an equitable fashion (if all agents act equitably, we can say that the behavioral equity norm is reached (ideally, there should be some time frame where all or most agents must have acted equitably))
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



function checkStoppingCondition(::Game, stopping_condition::PeriodCutoff, ::AgentGraph, current_periods::Int128)
    return current_periods >= stopping_condition.period_cutoff
end




function countStrats(memory_set::PerceptSequence, desired_strat::Int8)
    count::Int64 = 0
    for memory in memory_set
        if memory == desired_strat
            count += 1
        end
    end
    return count
end

#tagged functionality
# function countStrats(memory_set::Vector{Tuple{Symbol, Int8}}, desired_strat)
#     count::Int64 = 0
#     for memory in memory_set
#         if memory[2] == desired_strat
#             count += 1
#         end
#     end
#     return count
# end

