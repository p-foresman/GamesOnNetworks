# using JSON3, Graphs, MetaGraphs

# include("types.jl")
include("sql.jl")

function pushToDatabase(sim_group_id::Integer, prev_simulation_id::Integer, game::Game, sim_params::SimParams, graph_params::GraphParams, graph::AbstractGraph, periods_elapsed::Integer, use_seed::Bool)

    #prepare and instert data for "games" table. No duplicate rows.
    game_name = game.name
    game_json_str = JSON3.write(game)
    payoff_matrix_size = JSON3.write(size(game.payoff_matrix))
    game_insert_result = insertGame(game_name, game_json_str, payoff_matrix_size)
    game_status = game_insert_result.status_message
    game_row_id = game_insert_result.insert_row_id

    #prepare and insert data for "graphs" table. No duplicate rows.
    graph_type = displayName(graph_params)
    graph_params_string = JSON3.write(graph_params)
    db_params_dict = Dict{Symbol, Any}(:λ => nothing, :κ => nothing, :β => nothing, :α => nothing, :communities => nothing, :internal_λ => nothing, :external_λ => nothing) #allows for parameter-based queries
    for param in keys(db_params_dict)
        if param in fieldnames(typeof(graph_params))
            db_params_dict[param] = getfield(graph_params, param)
        end
    end
    graph_insert_result = insertGraph(graph_type, graph_params_string, db_params_dict)
    graph_status = graph_insert_result.status_message
    graph_row_id = graph_insert_result.insert_row_id

    #prepare and insert data for "sim_params" table. Duplicate rows necessary.
    sim_params_json_str = JSON3.write(sim_params)
    if use_seed == true
        seed_bool = 1
    else
        seed_bool = 0
    end
    sim_params_insert_result = insertSimParams(sim_params, sim_params_json_str, seed_bool)
    sim_params_status = sim_params_insert_result.status_message
    sim_params_row_id = sim_params_insert_result.insert_row_id

    #prepare and insert data for "simulations" table. Duplicate rows necessary.
    adj_matrix_json_str = JSON3.write(Matrix(adjacency_matrix(graph)))
    rng_state = copy(Random.default_rng())
    rng_state_json = JSON3.write(rng_state)

    simulation_insert_result = insertSimulation(sim_group_id, prev_simulation_id, game_row_id, graph_row_id, sim_params_row_id, adj_matrix_json_str, rng_state_json, periods_elapsed)
    simulation_status = simulation_insert_result.status_message
    simulation_row_id = simulation_insert_result.insert_row_id

    #create agents list to insert all agents into "agents" table at once
    agents_list = Vector{String}([])
    for vertex in vertices(graph)
        agent = get_prop(graph, vertex, :agent)
        agent_json_str = JSON3.write(agent) #StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable() defined after struct is defined
        push!(agents_list, agent_json_str)
    end
    agents_status = insertAgents(simulation_row_id, agents_list)

    return (game_status=game_insert_result, graph_status=graph_insert_result, sim_params_status=sim_params_insert_result, simulation_status=simulation_insert_result, agents_status=agents_status)
end


function restoreFromDatabase(simulation_id::Integer)
    simulation_df = querySimulationForRestore(simulation_id)
    agents_df = queryAgentsForRestore(simulation_id)

    #reproduce SimParams object
    reproduced_sim_params = JSON3.read(simulation_df[1, :sim_params], SimParams)

    #reproduce Game object
    payoff_matrix_size = JSON3.read(simulation_df[1, :payoff_matrix_size], Tuple)
    reproduced_game = JSON3.read(simulation_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2]})

    #reproduced Graph     ###!! dont need to reproduce graph unless the simulation is a pure continuation of 1 long simulation !!###
    reproduced_graph_params = JSON3.read(simulation_df[1, :graph_params], GraphParams)
    reproduced_adj_matrix = JSON3.read(simulation_df[1, :graph_adj_matrix], MMatrix{reproduced_sim_params.number_agents, reproduced_sim_params.number_agents, Int})
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
    return (game=reproduced_game, sim_params=reproduced_sim_params, graph_params=reproduced_graph_params, meta_graph=reproduced_meta_graph, use_seed=seed_bool, periods_elapsed=simulation_df[1, :periods_elapsed], sim_group_id=simulation_df[1, :sim_group_id])
end