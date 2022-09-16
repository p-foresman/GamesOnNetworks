using JSON3, Graphs, MetaGraphs

include("types.jl")
include("sql.jl")

function pushToDatabase(grouping_id::Int, game::Game, params::SimParams, graph_params_dict::Dict{Symbol, Any}, graph::AbstractGraph, periods_elapsed::Integer, use_seed::Bool)

    initDataBase()

    #prepare and instert data for "games" table. No duplicate rows.
    game_name = game.name
    game_json_str = JSON3.write(game)
    payoff_matrix_size = JSON3.write(size(game.payoff_matrix))
    game_insert_result = insertGame(game_name, game_json_str, payoff_matrix_size)
    game_status = game_insert_result.status_message
    game_row_id = game_insert_result.insert_row_id

    #prepare and insert data for "graphs" table. No duplicate rows.
    graph_type = String(graph_params_dict[:type])
    graph_params_string = JSON3.write(graph_params_dict)
    db_params_dict = Dict{Symbol, Any}(:λ => nothing, :k => nothing, :β => nothing, :α => nothing, :communities => nothing, :internal_λ => nothing, :external_λ => nothing) #allows for parameter-based queries
    for param in keys(db_params_dict)
        if haskey(graph_params_dict, param)
            db_params_dict[param] = graph_params_dict[param]
        end
    end
    graph_insert_result = insertGraph(graph_type, graph_params_string, db_params_dict)
    graph_status = graph_insert_result.status_message
    graph_row_id = graph_insert_result.insert_row_id

    #prepare and insert data for "simulations" table. Duplicate rows necessary.
    #description = "test description" Might want a description eventually. removed for now.
    params_json_str = JSON3.write(params)
    adj_matrix_json_str = JSON3.write(Matrix(adjacency_matrix(graph)))
    if use_seed == true
        seed_bool = 1
    else
        seed_bool = 0
    end
    rng_state = copy(Random.default_rng())
    rng_state_json = JSON3.write(rng_state)

    simulation_insert_result = insertSimulation(grouping_id, params, params_json_str, adj_matrix_json_str, periods_elapsed, game_row_id, graph_row_id, seed_bool, rng_state_json)
    simulation_status = simulation_insert_result.status_message
    simulation_row_id = simulation_insert_result.insert_row_id

    #create agents list to insert all agents into "agents" table at once
    agents_list = Vector{String}([])
    for vertex in vertices(graph)
        agent = get_prop(graph, vertex, :agent)
        agent_json_str = JSON3.write(agent) #StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable() defined after struct is defined
        push!(agents_list, agent_json_str)
    end
    agents_status = insertAgents(agents_list, simulation_row_id)

    return game_status, graph_status, simulation_status, agents_status
end


function restoreFromDatabase(simulation_id::Integer)
    simulation_df = querySimulationForRestore(simulation_id)
    agents_df = queryAgentsForRestore(simulation_id)

    #reproduce SimParams object
    reproduced_params = JSON3.read(simulation_df[1, :sim_params], SimParams)

    #reproduce Game object
    payoff_matrix_size = JSON3.read(simulation_df[1, :payoff_matrix_size], Tuple)
    reproduced_game = JSON3.read(simulation_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2]})

    #reproduced Graph
    reproduced_graph_params_dict = JSON3.read(simulation_df[1, :graph_params_dict], Dict{Symbol, Any})
    reproduced_adj_matrix = JSON3.read(simulation_df[1, :graph_adj_matrix], MMatrx{reproduced_params.number_agents, reproduced_params.number_agents, Int})
    reproduced_graph = SimpleGraph(reproduced_adj_matrix)
    reproduced_meta_graph = MetaGraph(reproduced_graph)
    for vertex in vertices(reproduced_meta_graph)
        agent = JSON3.read(agents_df[vertex, :agent], Agent)
        set_prop!(reproduced_meta_graph, vertex, :agent, agent)
    end

    #restore RNG to previous state
    if simulation_df[1, :use_seed] == 1
        seed_bool = true
        reproduced_rng_state = JSON3.read(simulation_df[1, :rng_state], Random.Xoshiro)
        copy!(Random.default_rng(), reproduced_rng_state)
    else
        seed_bool = false
    end
    return (game=reproduced_game, params=reproduced_params, graph_params_dict=reproduced_graph_params_dict, meta_graph=reproduced_meta_graph, use_seed=seed_bool, periods_elapsed=simulation_df[1, :periods_elapsed], grouping_id=simulation_df[1, :grouping_id])
end