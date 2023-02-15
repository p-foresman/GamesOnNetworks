
############################### FUNCTIONS #######################################



######################## game algorithm ####################

#play the defined game
function playGame!(game::Game, sim_params::SimParams, players::Tuple{Agent, Agent}, pre_allocated_arrays::PreAllocatedArrays)
    resetArrays!(pre_allocated_arrays)
    makeChoices!(game, sim_params, players, pre_allocated_arrays)
    updateMemories!(players, sim_params)
    return nothing
end

#choice algorithm for agents "deciding" on strategies (find max expected payoff)
function makeChoices!(game::Game, sim_params::SimParams, players::Tuple{Agent, Agent}, pre_allocated_arrays::PreAllocatedArrays) #COULD LIKELY MAKE THIS FUNCTION BETTER. Could use CartesianIndices() to iterate through payoff matrix? 
    # player_choices::Vector{Int8} = [rand(game.strategies[1]), rand(game.strategies[2])]
    
    #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
    #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
    #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.

    findOpponentStrategyProbs!(pre_allocated_arrays.opponent_strategy_recollection, pre_allocated_arrays.opponent_strategy_probs, players)
    findExpectedUtilities!(pre_allocated_arrays.player_expected_utilities, game.payoff_matrix, pre_allocated_arrays.opponent_strategy_probs)
    # print("player_expected_utilities: ")
    # println(player_expected_utilities)
    
    for player in eachindex(players)
        if rand() <= sim_params.error 
            players[player].choice = rand(game.strategies[player])
        else
            players[player].choice = findMaximumStrats(pre_allocated_arrays.player_expected_utilities[player])
        end
    end
    # print("player_choices: ")
    # println(player_choices)
    return nothing

    # outcome = game.payoff_matrix[player_choices[1], player_choices[2]] #don't need this right now (wealth is not being analyzed)
    # players[1].wealth += outcome[1]
    # players[2].wealth += outcome[2]
end



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
function updateMemories!(players::Tuple{Agent, Agent}, sim_params::SimParams)
    for player in players
        if length(player.memory) == sim_params.memory_length
            popfirst!(player.memory)
        end
    end
    push!(players[1].memory, (players[2].tag, players[2].choice))
    push!(players[2].memory, (players[1].tag, players[1].choice))
    return nothing
end

#######################################################



##### multiple dispatch for various graph parameter sets #####
function initGraph(::CompleteParams, game::Game, sim_params::SimParams)
    graph = complete_graph(sim_params.number_agents)
    agent_graph = AgentGraph{sim_params.number_agents}(graph)
    setAgentData!(agent_graph, game, sim_params)
    return agent_graph
end
function initGraph(graph_params::ErdosRenyiParams, game::Game, sim_params::SimParams)
    edge_probability = graph_params.λ / sim_params.number_agents
    graph = nothing
    while true
        graph = erdos_renyi(sim_params.number_agents, edge_probability)
        if length(collect(edges(graph))) >= 1 #simulation will break if graph has no edges
            break
        end
    end
    agent_graph = AgentGraph{sim_params.number_agents}(graph)
    setAgentData!(agent_graph, game, sim_params)
    return agent_graph
end
function initGraph(graph_params::SmallWorldParams, game::Game, sim_params::SimParams)
    graph = watts_strogatz(sim_params.number_agents, graph_params.κ, graph_params.β)
    agent_graph = AgentGraph{sim_params.number_agents}(graph)
    setAgentData!(agent_graph, game, sim_params)
    return agent_graph
end
function initGraph(graph_params::ScaleFreeParams, game::Game, sim_params::SimParams)
    m_count = Int64(floor(sim_params.number_agents ^ 1.5)) #this could be better defined
    graph = static_scale_free(sim_params.number_agents, m_count, graph_params.α)
    agent_graph = AgentGraph{sim_params.number_agents}(graph)
    setAgentData!(agent_graph, game, sim_params)
    return agent_graph
end
function initGraph(graph_params::StochasticBlockModelParams, game::Game, sim_params::SimParams)
    community_size = Int64(sim_params.number_agents / graph_params.communities)
    # println(community_size)
    internal_edge_probability = graph_params.internal_λ / community_size
    internal_edge_probability_vector = Vector{Float64}([])
    sizes_vector = Vector{Int64}([])
    for community in 1:graph_params.communities
        push!(internal_edge_probability_vector, internal_edge_probability)
        push!(sizes_vector, community_size)
    end
    external_edge_probability = graph_params.external_λ / sim_params.number_agents
    affinity_matrix = Graphs.SimpleGraphs.sbmaffinity(internal_edge_probability_vector, external_edge_probability, sizes_vector)
    graph = stochastic_block_model(affinity_matrix, sizes_vector)
    agent_graph = AgentGraph{sim_params.number_agents}(graph)
    setAgentData!(agent_graph, game, sim_params)
    return agent_graph
end


function setAgentData!(agent_graph::AgentGraph, game::Game, sim_params::SimParams)
    for (vertex, agent) in enumerate(agent_graph.agents)
        if rand() <= sim_params.tag1_proportion
            agent.tag = sim_params.tag1
        else
            agent.tag = sim_params.tag2
        end

        #set memory initialization
        #initialize in strict fractious state for now
        if vertex % 2 == 0
            recollection = game.strategies[1][1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
        else
            recollection = game.strategies[1][3]
        end
        to_push = (agent.tag, recollection)
        for i in 1:sim_params.memory_length
            push!(agent.memory, to_push)
        end
    end
    return nothing
end


#check whether transition has occured
function checkTransition(agent_graph::AgentGraph, sim_params::SimParams)
    number_transitioned = 0
    number_hermits = 0 #ensure that hermit agents are not considered in transition determination
    for (vertex, agent) in enumerate(agent_graph.agents)
        if degree(agent_graph.graph, vertex) == 0
            number_hermits += 1
            continue
        end

        if countStrats(agent.memory, 2) >= sim_params.sufficient_equity #this is hard coded to strategy 2 (M) for now. Should change later!
            number_transitioned += 1
        end
        # println(number_transitioned)
    end 
    if number_transitioned >= sim_params.number_agents - number_hermits
        return true
    else
        return false
    end
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

#sets the number of CPU cores to be used
# function setCores(desired_cores)
#     println("number cores before: $(nprocs())")
#     current_cores = nprocs()
#     if desired_cores > current_cores
#         addprocs(desired_cores - current_cores)
#     elseif desired_cores < current_cores
#         ids_to_remove = collect(current_cores - desired_cores:current_cores)
#         rmprocs(ids_to_remove)
#     else
#     end
#     println("number cores before: $(nprocs())")
#     return nothing
# end



############################### MAIN TRANSITION TIME SIMULATION #######################################

function runPeriod!(agent_graph, graph_edges, game, sim_params, pre_allocated_arrays::PreAllocatedArrays)
    for match in 1:sim_params.matches_per_period
        edge = rand(graph_edges) #get random edge
        vertex_list = shuffle!([edge.src, edge.dst]) #shuffle (randomize) the nodes connected to the edge
        players = Tuple{Agent, Agent}([agent_graph.agents[vertex] for vertex in vertex_list]) #get the agents associated with these vertices and create a tuple => (player1, player2)
        #println(players[1].name * " playing game with " * players[2].name)
        playGame!(game, sim_params, players, pre_allocated_arrays)
    end
    return nothing
end


function simulateTransitionTime(game::Game, sim_params::SimParams, graph_params::GraphParams; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false, db_filepath::Union{String, Nothing} = nothing, db_store_period::Union{Integer, Nothing} = nothing, db_sim_group_id::Union{Integer, Nothing} = nothing, db_game_id::Union{Integer, Nothing} = nothing, db_graph_id::Union{Integer, Nothing} = nothing, db_sim_params_id::Union{Integer, Nothing} = nothing, prev_simulation_uuid::Union{String, Nothing} = nothing, distributed_uuid::Union{String, Nothing} = nothing)
    if use_seed == true && prev_simulation_uuid === nothing #set seed only if the simulation has no past runs
        Random.seed!(sim_params.random_seed)
    end
    #create graph and subsequent metagraph to hold node metadata (associate node with agent object)
    agent_graph = initGraph(graph_params, game, sim_params)
    graph_edges = collect(edges(agent_graph.graph)) #collect here to avoid excessive allocations in loop (collect() is DANGEROUS in loop)
    #println(graph.fadjlist)
    #println(adjacency_matrix(graph)[1, 2])

    #play game until transition occurs (sufficient equity is reached)
    pre_allocated_arrays = PreAllocatedArrays(game.payoff_matrix) #construct these arrays outside of main loop to avoid excessive allocations
    # opponent_strategy_recollection = zeros.(Int64, size(game.payoff_matrix))
    # opponent_strategy_probs = zeros.(Float64, size(game.payoff_matrix))
    # player_expected_utilities = zeros.(Float32, size(game.payoff_matrix))
    while !checkTransition(agent_graph, sim_params)
        #play a period worth of games
        runPeriod!(agent_graph, graph_edges, game, sim_params, pre_allocated_arrays)
        periods_elapsed += 1
        if db_filepath !== nothing && db_store_period !== nothing && periods_elapsed % db_store_period == 0 #push incremental results to DB
            db_status = pushSimulationToDB(db_filepath, db_sim_group_id, prev_simulation_uuid, db_game_id, db_graph_id, db_sim_params_id, agent_graph, periods_elapsed, distributed_uuid)
            prev_simulation_uuid = db_status.simulation_uuid
        end
    end
    println(" --> periods elapsed: $periods_elapsed")
    if db_filepath !== nothing #push final results to DB at filepath
        db_status = pushSimulationToDB(db_filepath, db_sim_group_id, prev_simulation_uuid, db_game_id, db_graph_id, db_sim_params_id, agent_graph, periods_elapsed, distributed_uuid)
        return (periods_elapsed, db_status)
    end
    return periods_elapsed
end


function simulationIterator(game::Game, sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}; run_count::Integer = 1, use_seed::Bool = false, db_filepath::Union{String, Nothing} = nothing, db_store_period::Union{Integer, Nothing} = nothing, db_sim_group_id::Union{Integer, Nothing} = nothing)
    distributed_uuid = "$(uuid4())"
    
    if db_filepath === nothing && db_sim_group_id !== nothing
        throw(ArgumentError("The dm_sim_group_id parameter was specified without a db_filepath. Provide a db_filepath to store to database"))
    end

    if db_filepath !== nothing && nworkers() > 1
        initDistributedDB(distributed_uuid)
    end

    db_game_id = db_filepath !== nothing ? pushGameToDB(db_filepath, game) : nothing

    for graph_params in graph_params_list
        println("\n\n\n")
        println(displayName(graph_params))
        println(dump(graph_params))

        db_graph_id = db_filepath !== nothing ? pushGraphToDB(db_filepath, graph_params) : nothing

        for sim_params in sim_params_list            
            print("Number of agents: $(sim_params.number_agents), ")
            print("Memory length: $(sim_params.memory_length), ")
            println("Error: $(sim_params.error)")

            db_sim_params_id = db_filepath !== nothing ? pushSimParamsToDB(db_filepath, sim_params, use_seed) : nothing

            # run simulation (could have a parameter in simulationIterator that specifies the actual simulation function (in this case simulateTransitionTime) to run)
            @sync @distributed for run in 1:run_count
                print("Run $run of $run_count")
                simulateTransitionTime(game, sim_params, graph_params, use_seed=use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_sim_group_id=db_sim_group_id, db_game_id=db_game_id, db_graph_id=db_graph_id, db_sim_params_id=db_sim_params_id, distributed_uuid=distributed_uuid)
            end
        end
    end

    if db_filepath !== nothing && nworkers() > 1
        collectDistributedDB(db_filepath, distributed_uuid)
    end
end

#used to continue a simulation
function simGroupIterator(db_sim_group_id::Integer; db_store::Bool = false, db_filepath::String, db_store_period::Int = 0)
    simulation_ids_df = querySimulationIDsByGroup(db_filepath, db_sim_group_id)
    for row in eachrow(simulation_ids_df)
        continueSimulation(row[:simulation_id], db_store=db_store, db_filepath=db_filepath, db_store_period=db_store_period)
    end
end


function continueSimulation(db_simulation_id::Integer; db_store::Bool = false, db_filepath::String, db_store_period::Integer = 0)
    prev_sim = restoreFromDatabase(db_filepath, db_simulation_id)
    sim_results = simulateTransitionTime(prev_sim.game, prev_sim.sim_params, prev_sim.graph_params, use_seed=prev_sim.use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_sim_group_id=prev_sim.sim_group_id, prev_simulation_uuid=prev_sim.prev_simulation_uuid)
end