using Graphs, MetaGraphs, GraphPlot, Cairo, Fontconfig, Random, Plots, Statistics, StatsPlots, DataFrames, CSV, JSON3, BenchmarkTools

include("database_api.jl")
include("setup_params.jl")

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
end



#choice algorithm for agents "deciding" on strategies (find max expected payoff)
function makeChoice(game::Game, players::Tuple{Agent, Agent}; player_number::Int8) #COULD LIKELY MAKE THIS FUNCTION BETTER. Could use CartesianIndices() to iterate through payoff matrix?
    if player_number == 1
        player = players[1]
        player_strategies = game.strategies[1]
        opponent = players[2]
        opponent_strategies = game.strategies[2]
    else
        player = players[2]
        player_strategies = game.strategies[2]
        opponent = players[1]
        opponent_strategies = game.strategies[1]
    end
    player_memory_length = count(i->(i[1] == opponent.tag), player.memory) #tag specific! (these should both work fine without tags too)
    #print("memory length: ")
    #println(memory_length)
    player_recollection = [count(i->(i[1]==opponent.tag && i[2]==strategy), player.memory) for strategy in opponent_strategies]
    #println("decision process here...")
    #print("recollection: ")
    #println(player_recollection)
    opponent_probs = [i / player_memory_length for i in player_recollection]
    #print("probs: ")
    #println(opponent_probs)
    
    expected_utilities = zeros(Float32, length(player_strategies))
    for i in 1:length(game.strategies[1]) #row strategies
        for j in 1:length(game.strategies[2]) #column strategies
            if player_number == 1
                expected_utilities[i] += game.payoff_matrix[i, j][player_number] * opponent_probs[j]
            else
                expected_utilities[j] += game.payoff_matrix[i, j][player_number] * opponent_probs[i]
            end
        end
    end
    #println(player_number)
    #print("utilities: ")
    #println(expected_utilities)
    max_value = maximum(expected_utilities)
    #println(max_value)
    max_positions = findall(i->(i==max_value), expected_utilities)
    #println(max_positions)
    player_choice_index = rand(max_positions)
    player_choice = player_strategies[player_choice_index]
    #println(player_choice)
    return player_choice
end

#update agent's memory vector
function updateMemory!(player::Agent, opponent::Agent, opponent_choice::Int8, params::SimParams)
    to_push = (opponent.tag, opponent_choice)
    if length(player.memory) == params.memory_length
        popfirst!(player.memory)
    end
    push!(player.memory, to_push)
end

#play the defined game
function playGame!(game::Game, params::SimParams, players::Tuple{Agent, Agent})
    player1_memory_length = count(i->(i[1] == players[2].tag), players[1].memory)  #tag specific! (these should both
    player2_memory_length = count(i->(i[1] == players[1].tag), players[2].memory)  #work fine without tags too)
    if player1_memory_length == 0 || rand() <= params.error
        player1_choice = game.strategies[1][rand(1:length(game.strategies[1]))]
    else
        player1_choice = makeChoice(game, players; player_number = Int8(1))
        #println(player1_choice)
    end
    if player2_memory_length == 0 || rand() <= params.error
        player2_choice = game.strategies[2][rand(1:length(game.strategies[2]))]
    else
        player2_choice = makeChoice(game, players; player_number = Int8(2))
        #println(player2_choice)
    end
    #outcome = game.payoff_matrix[player1_choice, player2_choice] #don't need this right now (wealth is not being analyzed)
    #players[1].wealth += outcome[1]
    #players[2].wealth += outcome[2]
    updateMemory!(players[1], players[2], player2_choice, params)
    updateMemory!(players[2], players[1], player1_choice, params)
end


########################### New game functions below ##############################

#choice algorithm for agents "deciding" on strategies (find max expected payoff)
function makeChoices(game::Game, params::SimParams, players::Tuple{Agent, Agent}) #COULD LIKELY MAKE THIS FUNCTION BETTER. Could use CartesianIndices() to iterate through payoff matrix?
    number_players = length(players)
    player_memory_lengths = (count(i->(i[1] == players[2].tag), players[1].memory), count(i->(i[1] == players[1].tag), players[2].memory)) #tag specific! Could iterate through players tuple somehow to obtaain this?

    #print("memory length: ")
    #println(memory_length)
    opponent_strategy_recollections = ([count(i->(i[1]==players[2].tag && i[2]==strategy), players[1].memory) for strategy in game.strategies[2]], [count(i->(i[1]==players[1].tag && i[2]==strategy), players[2].memory) for strategy in game.strategies[1]])
    #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
    #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
    #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.

    #println("decision process here...")
    #print("recollection: ")
    #println(player_recollection)
    opponent_strategy_probs = [[i / player_memory_lengths[player] for i in opponent_strategy_recollections[player]] for player in 1:number_players]
    println(opponent_strategy_recollections)
    println(typeof(opponent_strategy_recollections))
    #print("probs: ")
    #println(opponent_probs)
    player_expected_utilities = [zeros(Float32, length(game.strategies[player])) for player in 1:number_players]
    # for row in 1:size(game.payoff_matrix, 1) #row strategies
    #     for column in 1:size(game.payoff_matrix, 2) #column strategies
    #         player_expected_utilities[1][row] += game.payoff_matrix[row, column][1] * opponent_strategy_probs[1][column]
    #         player_expected_utilities[2][column] += game.payoff_matrix[row, column][2] * opponent_strategy_probs[2][row]
    #     end
    # end

    #this should be equivalent to above. make sure and see which is more efficient
    for index in CartesianIndices(game.payoff_matrix) #index in form (row, column)
        player_expected_utilities[1][index[1]] += game.payoff_matrix[index[1], index[2]][1] * opponent_strategy_probs[1][index[2]]
        player_expected_utilities[2][index[2]] += game.payoff_matrix[index[1], index[2]][2] * opponent_strategy_probs[2][index[1]]
    end

    #println(player_number)
    #print("utilities: ")
    #println(expected_utilities)
    player_max_values = (maximum(expected_utilities) for expected_utilities in player_expected_utilities)
    #println(max_value)
    player_max_positions = (findall(i->(i==player_max_values[player]), player_expected_utilities[player]) for player in 1:number_players)
    #println(max_positions)
    player_choices = (game.strategies[player][rand(player_max_positions[player])] for player in 1:number_players)
    #println(player_choice)
    for player in 1:number_players
        if rand() <= params.error
            player_choices[player] = rand(game.strategies[player])
        end
    end
    return player_choices
end

#update agent's memory vector
function updateMemories!(players::Tuple{Agent, Agent}, player_choices::Tuple{Int8, Int8}, params::SimParams)
    for player in players
        if length(player.memory) == params.memory_length
            popfirst!(player.memory)
        end
    end
    push!(players[1].memory, (players[2].tag, player_choices[2]))
    push!(players[2].memory, (players[1].tag, player_choices[1]))
    return nothing
end

#play the defined game
function playGameUpdated!(game::Game, params::SimParams, players::Tuple{Agent, Agent})

    player_choices = makeChoices(game, params, players)

    #outcome = game.payoff_matrix[player1_choice, player2_choice] #don't need this right now (wealth is not being analyzed)
    #players[1].wealth += outcome[1]
    #players[2].wealth += outcome[2]

    updateMemories!(players, player_choices, params)
    return nothing
end

##############################################################################################

#ensure all nodes have at least a degree of one (not used)
function ensureOneDegree(params) #make params a dictionary????
    graph = nothing
    good_graph = false
    while good_graph == false
        graph = erdos_renyi(params, 0.1) #params = number agents here
        zero_degree_counter = 0
        for vertex in degree(graph)
            if vertex == 0
                zero_degree_counter += 1
            end
        end
        if zero_degree_counter == 0
            good_graph = true
        end
    end
    println("good graph!")
    return graph
end


function initGraph(graph_params::Dict, game::Game, params::SimParams)
    graph_type = graph_params[:type]
    if graph_type == :complete
        graph = complete_graph(params.number_agents)
    elseif graph_type == :er
        probability = graph_params[:λ] / params.number_agents
        while true
            graph = erdos_renyi(params.number_agents, probability)
            if length(collect(edges(graph))) >= 1 #simulation will break if graph has no edges
                break
            end
        end
    elseif graph_type == :sw
        graph = watts_strogatz(params.number_agents, graph_params[:k], graph_params[:β])
    elseif graph_type == :sf
        m_count = Int64(floor(params.number_agents ^ 1.5)) #this could be better defined
        graph = static_scale_free(params.number_agents, m_count, graph_params[:α])
    elseif graph_type == :sbm
        community_size = Int64(params.number_agents / graph_params[:communities])
        # println(community_size)
        internal_probability = graph_params[:internal_λ] / community_size
        internal_probability_vector = Vector{Float64}([])
        sizes_vector = Vector{Int64}([])
        for community in 1:graph_params[:communities]
            push!(internal_probability_vector, internal_probability)
            push!(sizes_vector, community_size)
        end
        external_probability = graph_params[:external_λ] / params.number_agents
        affinity_matrix = Graphs.SimpleGraphs.sbmaffinity(internal_probability_vector, external_probability, sizes_vector)
        graph = stochastic_block_model(affinity_matrix, sizes_vector)
    end

    meta_graph = setGraphMetaData!(graph, game, params)
    return meta_graph
end


#set metadata properties for all vertices
function setGraphMetaData!(graph::Graph, game::Game, params::SimParams)
    meta_graph = MetaGraph(graph)
    for vertex in vertices(meta_graph)
        if rand() <= params.tag1_proportion
            agent = Agent("Agent $vertex", params.tag1)
        else
            agent = Agent("Agent $vertex", params.tag2)
        end

        #set memory initialization
        #initialize in strict fractious state for now
        if vertex % 2 == 0
            recollection = game.strategies[1][1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
        else
            recollection = game.strategies[1][3]
        end
        to_push = (agent.tag, recollection)
        for i in 1:params.memory_length
            push!(agent.memory, to_push)
        end
        set_prop!(meta_graph, vertex, :agent, agent)
        #println(props(meta_graph, vertex))
        #println(get_prop(meta_graph, vertex, :agent).name)
    end
    return meta_graph
end


function initLinePlot(params::SimParams)
    if params.iteration_param == :memorylength
        x_label = "Memory Length"
        x_lims = (8,20)
        x_ticks = 8:1:20
    elseif params.iteration_param == :numberagents
        x_label = "Number of Agents"
        x_lims = (0,110)
        x_ticks = 0:10:100
    end
    sim_plot = plot(xlabel = x_label,
                    xlims = x_lims,
                    xticks = x_ticks,
                    ylabel = "Transition Time",
                    yscale = :log10,
                    legend_position = :topleft)
    return sim_plot
end


#check whether transition has occured
function checkTransition(meta_graph::AbstractGraph, game::Game, params::SimParams)
    number_transitioned = 0
    number_hermits = 0 #ensure that hermit agents are not considered in transition determination
    for vertex in vertices(meta_graph)
        if degree(meta_graph, vertex) == 0
            number_hermits += 1
            continue
        end
        agent = get_prop(meta_graph, vertex, :agent)
        count_M = count(i->(i[2] == game.strategies[1][2]), agent.memory) #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
        # println("here!")
        # println(sufficient_equity)
        # println(count_M)
        if count_M >= params.sufficient_equity
            number_transitioned += 1
        end
        # println(number_transitioned)
    end
    if number_transitioned >= params.number_agents - number_hermits
        return true
    else
        return false
    end
end



############################### MAIN TRANSITION TIME SIMULATION #######################################



function simulate(game::Game, params::SimParams, graph_params_dict::Dict{Symbol, Any}; use_seed::Bool = false, db_store::Bool = false)
    if use_seed == true
        Random.seed!(params.random_seed)
    end
    #setup new graph to ensure no artifacts from last game
    #create graph and subsequent metagraph to hold node metadata (associate node with agent object)
    meta_graph = initGraph(graph_params_dict, game, params)
    #println(graph.fadjlist)
    #println(adjacency_matrix(graph)[1, 2])

    
    #play game until transition occurs (sufficient equity is reached)
    periods_elapsed = 0
    while !checkTransition(meta_graph, game, params)
        #play a period worth of games
        for match in 1:params.matches_per_period
            edge = rand(collect(edges(meta_graph))) #get random edge
            vertex_list = shuffle!([edge.src, edge.dst]) #shuffle (randomize) the nodes connected to the edge
            #=
            must do shuffle this vector because src and dst 
            always make a lower to higher pair of vertices, meaning player1
            tends to be in lower 50% of vertices and vica versa. This means
            that these two halves of vertices are more likely to play
            against each other... not good.
            =#
            players = Tuple{Agent, Agent}([get_prop(meta_graph, vertex_list[1], :agent), get_prop(meta_graph, vertex_list[2], :agent)]) #get the agents associated with these vertices and create a tuple => (player1, player2)
            #println(players[1].name * " playing game with " * players[2].name)
            playGameUpdated!(game, params, players)
        end
        #increment period count
        periods_elapsed += 1
    end
    if db_store == true
        agent_df = pushToDatabase(game, params, graph_params_dict, meta_graph, periods_elapsed, use_seed)
        return agent_df
    end
    return periods_elapsed
end



function simIterator(game::Game, params_list::AbstractVector{SimParams}, graph_simulations_list::AbstractVector{Dict{Symbol, Any}}; averager::Int64 = 1, use_seed::Bool = false, db_store::Bool = false)
    #sim_plot = initLinePlot(params)
    #sim_plot = initBoxPlot(params, length(graph_simulations_list))
    #transition_times = Vector{AbstractFloat}([]) #vector to be updated
    #standard_errors = Vector{AbstractFloat}([])
    transition_times_matrix = rand(averager, length(graph_simulations_list))
    matrix_index = 1
    for graph_params_dict in graph_simulations_list
        println("\n\n")
        println(graph_params_dict[:plot_label])
        for params in params_list
            #transition_times = Vector{AbstractFloat}([]) #vector to be updated
            # standard_errors = Vector{AbstractFloat}([])
            
            print("Number of agents: $(params.number_agents), ")
            print("Memory length: $(params.memory_length), ")
            println("Error: $(params.error)")


            run_results = Vector{Integer}([])
            for run in 1:averager
                println("Run $run of $averager")

                periods_elapsed = simulate(game, params, graph_params_dict, use_seed=use_seed, db_store=false) #false for now
                push!(run_results, periods_elapsed)
            end
            println(run_results)
            transition_times_matrix[:, matrix_index] = run_results
            
            #average_transition_time = sum(run_results) / averager
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
        matrix_index += 1
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