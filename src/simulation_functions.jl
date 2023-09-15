
############################### FUNCTIONS #######################################

############### parameter initialization (for simulateIterator()) ############### NOTE:ADD MORE
function constructSimParamsList(;number_agents_start::Int64, number_agents_end::Int64, number_agents_step::Int64, memory_length_start::Int64, memory_length_end::Int64, memory_length_step::Int64, error_list::Vector{Float64}, tag1::Symbol, tag2::Symbol, tag1_proportion::Float64, random_seed::Int64)
    sim_params_list = Vector{SimParams}([])
    for number_agents in number_agents_start:number_agents_step:number_agents_end
        for memory_length in memory_length_start:memory_length_step:memory_length_end
            for error in error_list
                new_sim_params_set = SimParams(number_agents=number_agents, memory_length=memory_length, error=error, tag1=tag1, tag2=tag2, tag1_proportion=tag1_proportion, random_seed=random_seed)
                push!(sim_params_list, new_sim_params_set)
            end
        end
    end
    return sim_params_list
end


######################## game algorithm ####################

function setPlayers!(model::SimModel)
    edge = rand(model.agent_graph.edges)
    vertex_list = shuffle!([edge.src, edge.dst])
    for player in eachindex(model.pre_allocated_arrays.players) #NOTE: this will always be 2. Should I just optimize for two player games?
        model.pre_allocated_arrays.players[player] = model.agent_graph.agents[vertex_list[player]]
    end
end


function runPeriod!(model::SimModel) #NOTE: what type are graph_edges ??
    for match in 1:model.sim_params.matches_per_period
        setPlayers!(model)
        #println(players[1].name * " playing game with " * players[2].name)
        playGame!(model)
        resetArrays!(model)
    end
    return nothing
end


#play the defined game
function playGame!(model::SimModel)
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
    
    for player in eachindex(model.pre_allocated_arrays.players)
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
function calculateOpponentStrategyProbs!(player_memory, opponent_tag, opponent_strategy_recollection, opponent_strategy_probs)
    @inbounds for memory in player_memory
        if memory[1] == opponent_tag #if the opponent's tag is not present, no need to count strategies
            opponent_strategy_recollection[memory[2]] += 1 #memory strategy is simply the payoff_matrix index for the given dimension
        end
    end
    opponent_strategy_probs .= opponent_strategy_recollection ./ sum(opponent_strategy_recollection)
    return nothing
end


function findOpponentStrategyProbs!(opponent_strategy_recollection, opponent_strategy_probs, players)
    calculateOpponentStrategyProbs!(players[1].memory, players[2].tag, opponent_strategy_recollection[1], opponent_strategy_probs[1])
    calculateOpponentStrategyProbs!(players[2].memory, players[1].tag, opponent_strategy_recollection[2], opponent_strategy_probs[2])
    return nothing
end

function findExpectedUtilities!(player_expected_utilities, payoff_matrix, opponent_probs)
    @inbounds for column in axes(payoff_matrix, 2) #column strategies
        for row in axes(payoff_matrix, 1) #row strategies
            player_expected_utilities[1][row] += payoff_matrix[row, column][1] * opponent_probs[1][column]
            player_expected_utilities[2][column] += payoff_matrix[row, column][2] * opponent_probs[2][row]
        end
    end
    return nothing
end

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

#update agent's memory vector
function updateMemories!(players::SizedVector{2, Union{Nothing, Agent}}, sim_params::SimParams)
    for player in players
        if length(player.memory) == sim_params.memory_length
            popfirst!(player.memory)
        end
    end
    push!(players[1].memory, (players[2].tag, players[2].choice))
    push!(players[2].memory, (players[1].tag, players[1].choice))
    return nothing
end




######################## STUFF FOR DETERMINING AGENT BEHAVIOR (should combine this with above functions in the future) ###############################

function calculateExpectedOpponentProbs(game::Game, memory_set::Vector{Tuple{Symbol, T}} where T <: Integer)
    length = size(game.payoff_matrix, 1) #for symmetric games only
    opponent_strategy_recollection = zeros(Int64, length)
    for memory in memory_set
        opponent_strategy_recollection[memory[2]] += 1 #memory strategy is simply the payoff_matrix index for the given dimension
    end
    opponent_strategy_probs = opponent_strategy_recollection ./ sum(opponent_strategy_recollection)
    return opponent_strategy_probs
end


function calculateExpectedUtilities(game::Game, opponent_probs)
    payoff_matrix = game.payoff_matrix
    length = size(payoff_matrix, 1) #for symmetric games only
    player_expected_utilities = zeros(Float32, length)
    @inbounds for column in axes(game.payoff_matrix, 2) #column strategies
        for row in axes(game.payoff_matrix, 1) #row strategies
            player_expected_utilities[row] += payoff_matrix[row, column][1] * opponent_probs[column]
        end
    end
    return player_expected_utilities
end


function determineAgentBehavior(game::Game, memory_set::Vector{Tuple{Symbol, T}} where T <: Integer)
    opponent_strategy_probs = calculateExpectedOpponentProbs(game, memory_set)
    expected_utilities = calculateExpectedUtilities(game, opponent_strategy_probs)
    max_strat = findMaximumStrats(expected_utilities) #right now, if more than one strategy results in a max expected utility, a random strategy is chosen of the maximum strategies
    return max_strat
end

#######################################################

#NOTE: CAN REMOVE SIM_PARAMS FROM THESE! (ALL CALCULATIONS DONE IN MODEL INITIALIZATION)
function checkStoppingCondition(stopping_condition::EquityPsychological, agent_graph::AgentGraph, ::Integer) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
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

function checkStoppingCondition(stopping_condition::EquityBehavioral, agent_graph::AgentGraph, ::Integer) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    number_transitioned = 0
    for agent in agent_graph.agents
        if !agent.is_hermit
            if determineAgentBehavior(stopping_condition.game, agent.memory) == stopping_condition.strategy #if the agent is acting in an equitable fashion (if all agents act equitably, we can say that the behavioral equity norm is reached (ideally, there should be some time frame where all or most agents must have acted equitably))
                number_transitioned += 1
            end
        end
    end 
    if number_transitioned >= stopping_condition.sufficient_transitioned
        stopping_condition.period_count += 1
        return stopping_condition.period_count >= stopping_condition.period_limit
    else
        stopping_condition.period_count = 0 #reset period count
        return false
    end
end



function checkStoppingCondition(stopping_condition::PeriodCutoff, ::AgentGraph, current_periods::Integer)
    return current_periods >= stopping_condition.period_cutoff
end




function countStrats(memory_set::Vector{Tuple{Symbol, Int8}}, desired_strat)
    count::Int64 = 0
    for memory in memory_set
        if memory[2] == desired_strat
            count += 1
        end
    end
    return count
end

