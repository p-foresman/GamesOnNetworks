
############################### FUNCTIONS #######################################

############### parameter initialization (for simulateIterator()) ############### NOTE:ADD MORE
function constructSimParamsList(;number_agents_list::Vector{<:Integer}, memory_length_list::Vector{<:Integer}, error_list::Vector{Float64}, tags::Union{Nothing, NamedTuple{(:tag1, :tag2, :tag1_proportion), Tuple{Symbol, Symbol, Float64}}} = nothing, random_seed::Union{Nothing, Int64} = nothing)
    sim_params_list = Vector{SimParams}([])
    for number_agents in number_agents_list
        for memory_length in memory_length_list
            for error in error_list
                new_sim_params_set = SimParams(number_agents, memory_length, error, tags=tags, random_seed=random_seed)
                push!(sim_params_list, new_sim_params_set)
            end
        end
    end
    return sim_params_list
end


function constructModelList(;game_list::Vector{Game} , sim_params_list::Vector{SimParams}, graph_params_list::Vector{GraphParams}, starting_condition_list::Vector{StartingCondition}, stopping_condition_list::Vector{StoppingCondition}, slurm_task_id::Integer=nothing)
    model_list = Vector{SimModel}([])
    model_number::Int64 = 1
    for game in game_list
        for sim_params in sim_params_list
            for graph_params in graph_params_list
                for starting_condition in starting_condition_list
                    for stopping_condition in stopping_condition_list
                        if slurm_task_id === nothing || model_number == slurm_task_id #if slurm_task_id is present, 
                            push!(model_list, SimModel(game, sim_params, graph_params, starting_condition, stopping_condition, model_number))
                        end
                        model_number += 1
                    end
                end
            end
        end
    end
    return model_list
end

function selectAndConstructModel(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_params_list::Vector{GraphParams}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, model_number::Integer)
   #add validation here??  
    current_model_number::Int64 = 1
    for game in game_list
        for sim_params in sim_params_list
            for graph_params in graph_params_list
                for starting_condition in starting_condition_list
                    for stopping_condition in stopping_condition_list
                        if current_model_number == model_number
                            return SimModel(game, sim_params, graph_params, starting_condition, stopping_condition, model_number)
                        end
                        current_model_number += 1
                    end
                end
            end
        end
    end
end



######################## game algorithm ####################

function setPlayers!(model::SimModel)
    edge::Graphs.SimpleEdge{Int64} = rand(model.agent_graph.edges)
    vertex_list::Vector{Int64} = shuffle!([edge.src, edge.dst])
    for player in 1:2 #NOTE: this will always be 2. Should I just optimize for two player games?
        model.pre_allocated_arrays.players[player] = model.agent_graph.agents[vertex_list[player]]
    end
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


#play the defined game
function playGame!(model::SimModel)
    # @timeit to "make choices" makeChoices!(model)
    # @timeit to "update memories" updateMemories!(model.pre_allocated_arrays.players, model.sim_params)
    makeChoices!(model)
    updateMemories!(model.pre_allocated_arrays.players, model.sim_params)
    return nothing
end

#choice algorithm for agents "deciding" on strategies (find max expected payoff)
function makeChoices!(model::SimModel) #COULD LIKELY MAKE THIS FUNCTION BETTER. Could use CartesianIndices() to iterate through payoff matrix? 
    # player_choices::Vector{Int8} = [rand(game.strategies[1]), rand(game.strategies[2])]
    
    #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
    #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
    #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.

    findOpponentStrategyProbs!(model.pre_allocated_arrays.opponent_strategy_recollection, model.pre_allocated_arrays.opponent_strategy_probs, model.pre_allocated_arrays.players)
    findExpectedUtilities!(model.pre_allocated_arrays.player_expected_utilities, model.game.payoff_matrix, model.pre_allocated_arrays.opponent_strategy_probs)
    # print("player_expected_utilities: ")
    # println(player_expected_utilities)
    
    for player in 1:2 #eachindex(model.pre_allocated_arrays.players)
        if rand() <= model.sim_params.error 
            model.pre_allocated_arrays.players[player].choice = rand(model.game.strategies[player])
        else
            model.pre_allocated_arrays.players[player].choice = findMaximumStrats(model.pre_allocated_arrays.player_expected_utilities[player])
        end
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


#other player isn't even needed without tags. this could be simplified
function calculateOpponentStrategyProbs!(player_memory, opponent_strategy_recollection, opponent_strategy_probs)
    @inbounds for memory in player_memory
        opponent_strategy_recollection[memory] += 1 #memory strategy is simply the payoff_matrix index for the given dimension
    end
    opponent_strategy_probs .= opponent_strategy_recollection ./ sum(opponent_strategy_recollection)
    return nothing
end

function findOpponentStrategyProbs!(opponent_strategy_recollection, opponent_strategy_probs, players)
    for player in 1:2
        calculateOpponentStrategyProbs!(players[player].memory, opponent_strategy_recollection[player], opponent_strategy_probs[player])
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

# function findOpponentStrategyProbs!(opponent_strategy_recollection, opponent_strategy_probs, players)
#     calculateOpponentStrategyProbs!(players[1].memory, players[2].tag, opponent_strategy_recollection[1], opponent_strategy_probs[1])
#     calculateOpponentStrategyProbs!(players[2].memory, players[1].tag, opponent_strategy_recollection[2], opponent_strategy_probs[2])
#     return nothing
# end

# function updateMemories!(players::Vector{Agent}, sim_params::SimParams)
#     pushMemory!(players[1], (players[2].tag, players[2].choice), sim_params)
#     pushMemory!(players[2], (players[1].tag, players[1].choice), sim_params)
#     return nothing
# end



function findExpectedUtilities!(player_expected_utilities, payoff_matrix, opponent_probs)
    @inbounds for column in axes(payoff_matrix, 2) #column strategies
        for row in axes(payoff_matrix, 1) #row strategies
            player_expected_utilities[1][row] += payoff_matrix[row, column][1] * opponent_probs[1][column]
            player_expected_utilities[2][column] += payoff_matrix[row, column][2] * opponent_probs[2][row]
        end
    end
    return nothing
end


# function findExpectedUtilities!(player_expected_utilities, payoff_matrix, opponent_probs)
#     @inbounds for column in axes(payoff_matrix, 2) #column strategies
#         for row in axes(payoff_matrix, 1) #row strategies
#             player_expected_utilities[1][row] += payoff_matrix[row, column][1] * opponent_probs[1][column]
#             player_expected_utilities[2][column] += payoff_matrix[row, column][2] * opponent_probs[2][row]
#         end
#     end
#     return nothing
# end

function findMaximumStrats(expected_utilities::Vector{Float32})
    max_strats::Vector{Int8} = []
    max = maximum(expected_utilities)
    @inbounds for i in eachindex(expected_utilities)
        if expected_utilities[i] == max
            push!(max_strats, Int8(i))
        end
    end
    # print("max_strats: ")
    # println(max_strats)
    return rand(max_strats)
end

# update agent's memory vector
function pushMemory!(agent::Agent, percept::Percept, sim_params::SimParams)
    if length(agent.memory) == sim_params.memory_length
        popfirst!(agent.memory)
    end
    push!(agent.memory, percept)
    return nothing
end

function updateMemories!(players::Vector{Agent}, sim_params::SimParams)
    pushMemory!(players[1], players[2].choice, sim_params)
    pushMemory!(players[2], players[1].choice, sim_params)
    return nothing
end




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

