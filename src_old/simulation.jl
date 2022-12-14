using Graphs, MetaGraphs, Random, StaticArrays, DataFrames, JSON3, SQLite
include("types.jl")
include("setup_params.jl")
include("database_api.jl")

############################### FUNCTIONS #######################################

#memory state initialization
function memory_init(agent::Agent, game::Game, memory_length, init::String)
    if init == ""
        return
    elseif init == "fractious"
        if rand() <= 0.5
            recollection = game.strategies[1][1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
        else
            recollection = game.strategies[1][3]
        end

        to_push = (agent.tag, recollection)
        for i in 1:memory_length
            push!(agent.memory, to_push)
        end
    elseif init == "equity"
        recollection == game.strategies[1][2]
        to_push = (agent.tag, recollection)
        for i in 1:memory_length
            push!(agent.memory, to_push)
        end
    else
        throw(DomainError(init, "This is not an accepted memory initiallization."))
    end
    return nothing
end




#choice algorithm for agents "deciding" on strategies (find max expected payoff)
function makeChoices(game::Game, sim_params::SimParams, players::Tuple{Agent, Agent}) #COULD LIKELY MAKE THIS FUNCTION BETTER. Could use CartesianIndices() to iterate through payoff matrix? 
    player_choices::Vector{Int8} = [rand(game.strategies[1]), rand(game.strategies[2])]
    
    #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
    #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
    #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.

    function findOpponentStrategyProbs(player_memory, opponent_tag, opponent_strategies)
        opponent_strategy_recollection = zero.(opponent_strategies)
        for memory in player_memory
            if memory[1] == opponent_tag #if the opponent's tag is not present, no need to count strategies
                for strategy in opponent_strategies
                    if memory[2] == strategy
                        opponent_strategy_recollection[strategy] += 1 #strategy is simply the payoff_matrix index for the given dimension. Will remove explicit strategies eventually
                        break
                    end
                end
            end
        end
        return opponent_strategy_recollection ./ sum(opponent_strategy_recollection)
    end

    player_expected_utilities = zeros.(Float32, length.(game.strategies))
    function findExpectedUtilities!(expected_utilities, payoff_matrix, opponent_probs_1, opponent_probs_2)
        for column in axes(payoff_matrix, 2) #column strategies
            for row in axes(payoff_matrix, 1) #row strategies
                expected_utilities[1][row] += payoff_matrix[row, column][1] * opponent_probs_1[column]
                expected_utilities[2][column] += payoff_matrix[row, column][2] * opponent_probs_2[row]
            end
        end
    end
    findExpectedUtilities!(player_expected_utilities, game.payoff_matrix, findOpponentStrategyProbs(players[1].memory, players[2].tag, axes(game.payoff_matrix, 2)), findOpponentStrategyProbs(players[2].memory, players[1].tag, axes(game.payoff_matrix, 1)))
    # print("player_expected_utilities: ")
    # println(player_expected_utilities)
    
    function findMaximumStrats(expected_utilities::Vector{Float32})
        max_strats::Vector{Int8} = []
        max = maximum(expected_utilities)
        for i in eachindex(expected_utilities)
            if expected_utilities[i] == max
                push!(max_strats, Int8(i))
            end
        end
        # print("max_strats: ")
        # println(max_strats)
        return rand(max_strats)
    end
    for player in eachindex(players)
        if (rand() > sim_params.error) player_choices[player] = findMaximumStrats(player_expected_utilities[player]) end #if rand() <= error, do nothing (i.e., keep random choice)
    end
    # print("player_choices: ")
    # println(player_choices)
    return player_choices

    # outcome = game.payoff_matrix[player_choices[1], player_choices[2]] #don't need this right now (wealth is not being analyzed)
    # players[1].wealth += outcome[1]
    # players[2].wealth += outcome[2]
end


#update agent's memory vector
function updateMemories!(players::Tuple{Agent, Agent}, player_choices::Vector{Int8}, sim_params::SimParams)
    for player in players
        if length(player.memory) == sim_params.memory_length
            popfirst!(player.memory)
        end
    end
    push!(players[1].memory, (players[2].tag, player_choices[2]))
    push!(players[2].memory, (players[1].tag, player_choices[1]))
    return nothing
end

#play the defined game
function playGame!(game::Game, sim_params::SimParams, players::Tuple{Agent, Agent})
    player_choices = makeChoices(game, sim_params, players)
    updateMemories!(players, player_choices, sim_params)
    return nothing
end


##### multiple dispatch for various graph parameter sets #####
function initGraph(::CompleteParams, game::Game, sim_params::SimParams)
    graph = complete_graph(sim_params.number_agents)
    meta_graph = setGraphMetaData!(graph, game, sim_params)
    return meta_graph
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
    meta_graph = setGraphMetaData!(graph, game, sim_params)
    return meta_graph
end
function initGraph(graph_params::SmallWorldParams, game::Game, sim_params::SimParams)
    graph = watts_strogatz(sim_params.number_agents, graph_params.κ, graph_params.β)
    meta_graph = setGraphMetaData!(graph, game, sim_params)
    return meta_graph
end
function initGraph(graph_params::ScaleFreeParams, game::Game, sim_params::SimParams)
    m_count = Int64(floor(sim_params.number_agents ^ 1.5)) #this could be better defined
    graph = static_scale_free(sim_params.number_agents, m_count, graph_params.α)
    meta_graph = setGraphMetaData!(graph, game, sim_params)
    return meta_graph
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
    meta_graph = setGraphMetaData!(graph, game, sim_params)
    return meta_graph
end


#set metadata properties for all vertices
function setGraphMetaData!(graph::Graph, game::Game, sim_params::SimParams)
    meta_graph = MetaGraph(graph)
    for vertex in vertices(meta_graph)
        if rand() <= sim_params.tag1_proportion
            agent = Agent("Agent $vertex", sim_params.tag1)
        else
            agent = Agent("Agent $vertex", sim_params.tag2)
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
        set_prop!(meta_graph, vertex, :agent, agent)
        #println(props(meta_graph, vertex))
        #println(get_prop(meta_graph, vertex, :agent).name)
    end
    return meta_graph
end



#check whether transition has occured
function checkTransition(meta_graph::MetaGraph, game::Game, sim_params::SimParams)
    number_transitioned = 0
    number_hermits = 0 #ensure that hermit agents are not considered in transition determination
    for vertex in vertices(meta_graph)
        if degree(meta_graph, vertex) == 0
            number_hermits += 1
            continue
        end
        agent = get_prop(meta_graph, vertex, :agent)
        count_M = countStrats(agent.memory, 2) #this is hard coded to strategy 2 (M) for now. Should change later!

        # println("here!")
        # println(sufficient_equity)
        # println(count_M)
        if count_M >= sim_params.sufficient_equity
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

function countStrats(memory_set::Vector, desired_strat::Int64)
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



function simulateTransitionTime(game::Game, sim_params::SimParams, graph_params::GraphParams; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false, db_store::Bool = false, db_filepath::String = "", db_store_period::Integer = 0, db_sim_group_id::Integer = 0, prev_simulation_id::Integer = 0)
    if use_seed == true && prev_simulation_id == 0 #set seed only if the simulation has no past runs
        Random.seed!(sim_params.random_seed)
    end
    #create graph and subsequent metagraph to hold node metadata (associate node with agent object)
    meta_graph = initGraph(graph_params, game, sim_params)
    #println(graph.fadjlist)
    #println(adjacency_matrix(graph)[1, 2])

    #play game until transition occurs (sufficient equity is reached)
    while !checkTransition(meta_graph, game, sim_params)
        #play a period worth of games
        for match in 1:sim_params.matches_per_period
            edge = rand(collect(edges(meta_graph))) #get random edge
            vertex_list = shuffle!([edge.src, edge.dst]) #shuffle (randomize) the nodes connected to the edge
            players = Tuple{Agent, Agent}([get_prop(meta_graph, vertex_list[index], :agent) for index in eachindex(vertex_list)]) #get the agents associated with these vertices and create a tuple => (player1, player2)
            #println(players[1].name * " playing game with " * players[2].name)
            playGame!(game, sim_params, players)
        end
        periods_elapsed += 1
        if db_store == true && db_store_period != 0 && periods_elapsed % db_store_period == 0 #push incremental results to DB
            db_status = pushToDatabase(db_filepath, db_sim_group_id, prev_simulation_id, game, sim_params, graph_params, meta_graph, periods_elapsed, use_seed)
            prev_simulation_id = db_status.simulation_status.insert_row_id
        end
    end
    println(" --> periods elapsed: $periods_elapsed")
    if db_store == true #push final results to DB
        db_status = pushToDatabase(db_filepath, db_sim_group_id, prev_simulation_id, game, sim_params, graph_params, meta_graph, periods_elapsed, use_seed)
        return (periods_elapsed, db_status)
    end
    return (periods_elapsed)
end



function simulationIterator(; run_count::Integer = 1, use_seed::Bool = false, db_store::Bool = false, db_filepath::String = "", db_store_period::Integer = 0, db_sim_group_id::Integer = 0, db_sim_group_description::String = "")
    game, sim_params_list, graph_params_list = getSetupParams()

    if db_store == true
        if db_filepath == ""
            throw(ArgumentError("To store simulation run(s) in database, a db_filepath argument must be given specifying the database filepath!"))
        elseif db_sim_group_description != ""
            if db_sim_group_id != 0
                throw(ArgumentError("Specifying both 'db_sim_group_description' and 'db_sim_group_id' results in a conflict. Please specify 'db_sim_group_id' to add these simulation runs to an existing group or specify 'db_sim_group_description' to create a new group!"))
            else
                sim_group_insert_result = insertSimGroup(db_filepath, db_sim_group_description) #if a new description is present, it creates a new group and overrides the sim_group_id. A better system for this could be implemented.
                println(sim_group_insert_result.status_message)
                db_sim_group_id = sim_group_insert_result.insert_row_id
            end
        end
    end
    #sim_plot = initLinePlot(params)
    #sim_plot = initBoxPlot(params, length(graph_simulations_list))
    #transition_times = Vector{AbstractFloat}([]) #vector to be updated
    #standard_errors = Vector{AbstractFloat}([])
    # transition_times_matrix = rand(run_count, length(graph_simulations_list))
    # matrix_index = 1
    for graph_params in graph_params_list
        println("\n\n\n")
        println(displayName(graph_params))
        println(dump(graph_params))
        for sim_params in sim_params_list
            #transition_times = Vector{AbstractFloat}([]) #vector to be updated
            # standard_errors = Vector{AbstractFloat}([])
            
            print("Number of agents: $(sim_params.number_agents), ")
            print("Memory length: $(sim_params.memory_length), ")
            println("Error: $(sim_params.error)")

            @sync @distributed for run in 1:run_count
                print("Run $run of $run_count")
                simulateTransitionTime(game, sim_params, graph_params, use_seed=use_seed, db_store=db_store, db_filepath=db_filepath, db_store_period=db_store_period, db_sim_group_id=db_sim_group_id)
            end
            # transition_times_matrix[:, matrix_index] = run_results
            
            #average_transition_time = sum(run_results) / run_count
            #standard_deviation = std(run_results)
            #standard_error = standard_deviation / sqrt(params.number_agents)
            #push!(transition_times, average_transition_time)
            #push!(standard_errors, standard_error)
            
           
            #println(transition_times)

            # if params.error == 0.1
            #     line_style = :solid
            # else
            #     line_style = :dash
            # end

            # plot_label = graph_params_dict[:plot_label] * ", e=$error"

            # sim_plot = plot!(params.iterator, transition_times,
            #                                         label = plot_label,
            #                                         color = graph_params_dict[:line_color],
            #                                         linestyle = line_style
            #                                         )

            # sim_plot = plot!(params.iterator, transition_times,
            #                                         seriestype = :scatter,
            #                                         markercolor = :black,
            #                                         label = :none
            #                                         ) #for line under scatter 
            
        end
        # matrix_index += 1
    end

    #Plotting for box plot (all network classes)
    #= colors = [palette(:default)[11] palette(:default)[2] palette(:default)[2] palette(:default)[12] palette(:default)[9] palette(:default)[9] palette(:default)[9] palette(:default)[14]]
    x_vals = ["Complete" "ER λ=1" "ER λ=5" "SW" "SF α=2" "SF α=4" "SF α=8" "SBM"]
    sim_plot = boxplot(x_vals,
                   transition_times_matrix,
                    leg = false,
                    yscale = :log10,
                    xlabel = "Network",
                    ylabel = "Transtition Time (periods)",
                    fillcolor = colors) =#

    #return sim_plot
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
    sim_results = simulateTransitionTime(prev_sim.game, prev_sim.sim_params, prev_sim.graph_params, use_seed=prev_sim.use_seed, db_store=db_store, db_filepath=db_filepath, db_store_period=db_store_period, db_sim_group_id=prev_sim.sim_group_id, prev_simulation_id=prev_sim.prev_simulation_id)
end