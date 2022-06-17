using Graphs, MetaGraphs, GraphPlot, Cairo, Fontconfig, Random, Plots


############################### FUNCTIONS AND CONSTRUCTORS #######################################

#constructor for individual agents with relevant fields (mutable to update object later)
mutable struct Agent
    name::String
    tag::String
    wealth::Int
    memory::Vector{Tuple{String, Int}}

    function Agent(name, tag)
        return new(name, tag, 0, Vector{Int}([]))
    end
    function Agent()
        return new("", "", 0, Vector{Int}([]))
    end
end

#constructor for specific game to be played (mutable to update object later)
mutable struct Game
    name::String
    payoff_matrix::Matrix{Tuple{Int64, Int64}}
    strategies::Vector{Int64}
    player1::Agent
    player2::Agent

    function Game(name, payoff_matrix, strategies)
        new(name, payoff_matrix, strategies, Agent(), Agent())
    end
end

mutable struct SimParams
    number_agents::Int64
    memory_length::Int64
    error::Float64
    matches_per_period::Int64
    tag_proportion::Float64
    sufficient_equity::Float64
    tag1::AbstractString
    tag2::AbstractString
    m_init::AbstractString
end



#memory state initialization
function memory_init(agent::Agent, game::Game, memory_length, init::String)
    if init == ""
        return
    elseif init == "fractious"
        if rand() <= 0.5
            recollection = game.strategies[1]
        else
            recollection = game.strategies[3]
        end

        to_push = (agent.tag, recollection)
        for i in 1:memory_length
            push!(agent.memory, to_push)
        end
    elseif init == "equity"
        recollection == game.strategies[2]
        to_push = (agent.tag, recollection)
        for i in 1:memory_length
            push!(agent.memory, to_push)
        end
    else
        throw(DomainError(init, "This is not an accepted memory initiallization."))
    end
end



#choice algorithm for agents "deciding" on strategies (find max expected payoff)
function makeChoice(game::Game; player_number::Int)
    if player_number == 1
        player = game.player1
        opponent = game.player2
    else
        player = game.player2
        opponent = game.player1
    end
    player_memory_length = count(i->(i[1] == opponent.tag), player.memory) #tag specific! (these should both work fine without tags too)
    #print("memory length: ")
    #println(memory_length)
    player_recollection = [count(i->(i[1]==opponent.tag && i[2]==strategy), player.memory) for strategy in game.strategies]
    #println("decision process here...")
    #print("recollection: ")
    #println(player_recollection)
    opponent_probs = [i / player_memory_length for i in player_recollection]
    #print("probs: ")
    #println(opponent_probs)
    
    expected_utilities = zeros(Float32, length(game.strategies))
    for i in 1:length(game.strategies)
        for j in 1:length(game.strategies)
            if player_number == 1
                expected_utilities[i] += game.payoff_matrix[i, j][player_number] * opponent_probs[j]
            else
                expected_utilities[i] += game.payoff_matrix[j, i][player_number] * opponent_probs[j]
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
    player_choice = game.strategies[player_choice_index]
    #println(player_choice)
    return player_choice
end

#update agent's memory vector
function updateMemory(player::Agent, opponent::Agent, opponent_choice::Int, params::SimParams)
    to_push = (opponent.tag, opponent_choice)
    if length(player.memory) == params.memory_length
        popfirst!(player.memory)
    end
    push!(player.memory, to_push)
end

#play the defined game
function playGame(game::Game, params::SimParams)
    player1_memory_length = count(i->(i[1] == game.player2.tag), game.player1.memory)  #tag specific! (these should both
    player2_memory_length = count(i->(i[1] == game.player1.tag), game.player2.memory)  #work fine without tags too)
    if player1_memory_length == 0 || rand() <= params.error
        player1_choice = game.strategies[rand(1:length(game.strategies))]
    else
        player1_choice = makeChoice(game; player_number = 1)
        #println(player1_choice)
    end
    if player2_memory_length == 0 || rand() <= params.error
        player2_choice = game.strategies[rand(1:length(game.strategies))]
    else
        player2_choice = makeChoice(game; player_number = 2)
        #println(player2_choice)
    end
    outcome = game.payoff_matrix[player1_choice, player2_choice]
    #println(outcome)
    game.player1.wealth += outcome[1]
    game.player2.wealth += outcome[2]
    updateMemory(game.player1, game.player2, player2_choice, params)
    updateMemory(game.player2, game.player1, player1_choice, params)
end


#remove all nodes that have degree zero (solved below??? can delete if so)
function removeHermits(graph)
    edge_list = edges(graph)
    print(collect(edge_list))
    return SimpleGraphFromIterator(edge_list)
end

#ensure all nodes have at least a degree of one
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


#check whether transition has occured
function checkTransition(meta_graph::AbstractGraph, game::Game, params::SimParams)
    number_transitioned = 0
    number_hermits = 0 #ensure that hermit agents are not considered in transition determination
    graph_vertices = vertices(meta_graph)
    for vertex in graph_vertices
        if degree(meta_graph, vertex) == 0
            number_hermits += 1
            continue
        end
        agent = get_prop(meta_graph, vertex, :agent)
        count_M = count(i->(i[2] == game.strategies[2]), agent.memory)
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


############################### SIMULATION SETUP BELOW #######################################

function simInit()
    return
end





############################### EXECUTE TRANSITION TIME SIMULATION BELOW #######################################


function mainSim(game::Game, params::SimParams)
    transition_times = Vector{AbstractFloat}([]) #vector to be updated
    iterator = 7:3:19 #determines the values of the indepent variable (right now set for one iteration (memory lenght 10))
    #For loop here
    for i in iterator
        println(i)
        run_results = Vector{Integer}([])
        averager = 2 #how many runs to average out
        for run in 1:averager
            params.memory_length = i
            params.sufficient_equity = (1 - params.error) * params.memory_length
            println(params.sufficient_equity )
            #setup new graph to ensure no artifacts from last game
            #create graph and subsequent metagraph to hold node metadata (associate node with agent object)
            graph = complete_graph(params.number_agents)
            #graph = erdos_renyi(params.number_agents, 0.9)
            #graph = ensureOneDegree(number_agents)
            

            meta_graph = MetaGraph(graph)
            graph_vertices = vertices(meta_graph) #iterator of vertices in graph (use collect() for array)
            graph_edges = collect(edges(meta_graph)) #array of all edges in graph
                #println(graph.fadjlist)
                #println(adjacency_matrix(graph)[1, 2])








            #set metadata properties for all vertices
            for vertex in graph_vertices
                agent = Agent("Agent $vertex", "")
                if rand() <= params.tag_proportion
                    try
                        agent.tag = params.tag1
                    catch
                        #do nothing. leave agent tag as "" if no tag1 is defined (for more modular use)
                    end
                else
                    agent.tag = params.tag2
                end

                #memory_init(agent, game, m, m_init) #set memory initialization
                #initialize in strict fractious state for now
                if vertex % 2 == 0
                    recollection = game.strategies[1]
                else
                    recollection = game.strategies[3]
                end
                to_push = (agent.tag, recollection)
                for i in 1:params.memory_length
                    push!(agent.memory, to_push)
                end

                set_prop!(meta_graph, vertex, :agent, agent)
                #println(props(meta_graph, vertex))
                #println(get_prop(meta_graph, vertex, :agent).name)
            end

            #play game until transition occurs (sufficient equity is reached)
            periods_elapsed = 0
            transition = false
            while transition == false
                #play a period worth of games
                for match in 1:params.matches_per_period
                    edge = rand(graph_edges)
                    vertex_list = [edge.src, edge.dst]
                    rand_index = rand(1:2)     #must do this randomization process because src and dst 
                    if rand_index == 1         #always make a lower to higher pair of vertices, meaning player1
                        other_index = 2        #tends to be in lower 50% of vertices and vica versa. This means
                    else                       #that these two halves of vertices are more likely to play
                        other_index = 1        #against each other... not good.
                    end
                    vertex1 = vertex_list[rand_index]
                    vertex2 = vertex_list[other_index]
                    game.player1 = get_prop(meta_graph, vertex1, :agent)
                    game.player2 = get_prop(meta_graph, vertex2, :agent)
                    #println(game.player1.name * " playing game with " * game.player2.name)
                    playGame(game, params)
                end

                #increment period count
                periods_elapsed += 1
                
                if checkTransition(meta_graph, game, params)
                    push!(run_results, periods_elapsed)
                    transition = true
                end
            end
        end
        average_transition_time = sum(run_results) / averager
        push!(transition_times, average_transition_time)
    end
    println(transition_times)

            

    plot(iterator, transition_times,
        label = "e=0.10",
        color = :red,
        xlabel = "Memory Length",
        xlims = (5,20),
        xticks = 5:1:20,
        ylabel = "Transition Time",
        yscale = :log10
        )

    plot!(iterator, transition_times,
        seriestype = :scatter,
        markercolor = :black,
        label = :none
        ) #for line under scatter
end


#these initializations may be varied
number_agents = 10
matches_per_period = floor(number_agents / 2)
memory_length = 10
error = 0.10
tag_proportion = 1.0 #1.0 for effectively "no tags" (all agents get tag1)
sufficient_equity = (1 - error) * memory_length #can you instantiate this with struct function?
#number_periods = 80
tag1 = "red"
tag2 = "blue"
m_init = "fractious" #specifies initialization state

params = SimParams(number_agents, memory_length, error, matches_per_period, tag_proportion, sufficient_equity, tag1, tag2, m_init)


#set up game payoff matrix 
payoff_matrix = [(0, 0) (0, 0) (70, 30);
                (0, 0) (50, 50) (50, 30);
                (30, 70) (30, 50) (30, 30)]
strategies = [1, 2, 3] #corresponds to [High, Medium, Low]

#create bargaining game object (players will be slotted in)
game = Game("Bargaining Game", payoff_matrix, strategies)

mainSim(game, params)