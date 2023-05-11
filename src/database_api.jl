function createTempDirPath(db_filepath::String) rsplit(db_filepath, ".", limit=2)[1] * "/" end

function initDistributedDB(distributed_uuid::String) #creates a sparate sqlite file for each worker to prevent database locking conflicts (to later be collected).
    # temp_dirpath = createTempDirPath(db_filepath)
    temp_dirpath = distributed_uuid * "/"
    mkdir(temp_dirpath)
    for worker in workers()
        temp_filepath = temp_dirpath * "$worker.sqlite"
        initTempSimulationDB(temp_filepath)
    end
    return nothing
end

function collectDistributedDB(db_filepath::String, distributed_uuid::String) #collects distributed db files into the db_filepath 
    # temp_dirpath = createTempDirPath(db_filepath)
    temp_dirpath = distributed_uuid * "/"
    for worker in workers()
        temp_filepath = temp_dirpath * "$worker.sqlite"
        mergeTempDatabases(db_filepath, temp_filepath)
        rm(temp_filepath)
    end
    rm(temp_dirpath)
end


function collectDBFilesInDirectory(db_filepath::String, directory_path::String; cleanup_directory::Bool = false)
    files_to_collect = readdir(directory_path)
    for file in files_to_collect
        temp_filepath = directory_path * file
        println(temp_filepath)
        mergeTempDatabases(db_filepath, temp_filepath)
        cleanup_directory ? rm(temp_filepath) : nothing
    end
    cleanup_directory ? rm(directory_path) : nothing
end



function pushGameToDB(db_filepath::String, game::Game)
    game_name = game.name
    game_json_str = JSON3.write(game)
    payoff_matrix_size = JSON3.write(size(game.payoff_matrix))

    game_insert_result = insertGame(db_filepath, game_name, game_json_str, payoff_matrix_size)
    #game_status = game_insert_result.status_message
    game_row_id = game_insert_result.insert_row_id

    return game_row_id
end

function pushGraphToDB(db_filepath::String, graph_params::GraphParams)
    graph_type = displayName(graph_params)
    graph_params_string = JSON3.write(graph_params)
    db_params_dict = Dict{Symbol, Any}(:λ => nothing, :κ => nothing, :β => nothing, :α => nothing, :communities => nothing, :internal_λ => nothing, :external_λ => nothing) #allows for parameter-based queries
    
    for param in keys(db_params_dict)
        if param in fieldnames(typeof(graph_params))
            db_params_dict[param] = getfield(graph_params, param)
        end
    end

    graph_insert_result = insertGraph(db_filepath, graph_type, graph_params_string, db_params_dict)
    #graph_status = graph_insert_result.status_message
    graph_row_id = graph_insert_result.insert_row_id

    return graph_row_id
end

function pushSimParamsToDB(db_filepath::String, sim_params::SimParams, use_seed::Bool)
    sim_params_json_str = JSON3.write(sim_params)

    if use_seed == true
        seed_bool = 1
    else
        seed_bool = 0
    end

    sim_params_insert_result = insertSimParams(db_filepath, sim_params, sim_params_json_str, seed_bool)
    #sim_params_status = sim_params_insert_result.status_message
    sim_params_row_id = sim_params_insert_result.insert_row_id

    return sim_params_row_id
end

function pushSimulationToDB(db_filepath, sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, game_id::Integer, graph_id::Integer, sim_params_id::Integer, agent_graph::AgentGraph, periods_elapsed::Integer, distributed_uuid::Union{String, Nothing} = nothing)
    #prepare simulation to be inserted
    adj_matrix_json_str = JSON3.write(Matrix(adjacency_matrix(agent_graph.graph)))
    rng_state = copy(Random.default_rng())
    rng_state_json = JSON3.write(rng_state)

    #prepare agents to be inserted
    agents_list = Vector{String}([])
    for agent in agent_graph.agents
        agent_json_str = JSON3.write(agent) #StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable() defined after struct is defined
        push!(agents_list, agent_json_str)
    end


    if nworkers() > 1 #if the simulation is distributed, push to temp sqlite file to be collected later
        # temp_dirpath = createTempDirPath(db_filepath)
        temp_dirpath = distributed_uuid * "/"
        db_filepath = temp_dirpath * "$(myid()).sqlite" #get the current process's ID
    end


    simulation_insert_result = insertSimulationWithAgents(db_filepath, sim_group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, adj_matrix_json_str, rng_state_json, periods_elapsed, agents_list)
    #simulation_status = simulation_insert_result.status_message
    # simulation_uuid = simulation_insert_result.simulation_uuid
    return simulation_insert_result
end



function pullTimeSeriesDataFromDB(db_filepath, sim_group_id)
end


################## old method ######################


function pushToDatabase(db_filepath::String, sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, game::Game, sim_params::SimParams, graph_params::GraphParams, agent_graph::AgentGraph, periods_elapsed::Integer, use_seed::Bool, distributed_uuid::Union{String, Nothing} = nothing)
    #prepare and instert data for "games" table. No duplicate rows.
    game_name = game.name
    game_json_str = JSON3.write(game)
    payoff_matrix_size = JSON3.write(size(game.payoff_matrix))
    # game_insert_result = insertGame(db_filepath, game_name, game_json_str, payoff_matrix_size)
    # game_status = game_insert_result.status_message
    # game_row_id = game_insert_result.insert_row_id

    #prepare and insert data for "graphs" table. No duplicate rows.
    graph_type = displayName(graph_params)
    graph_params_string = JSON3.write(graph_params)
    db_params_dict = Dict{Symbol, Any}(:λ => nothing, :κ => nothing, :β => nothing, :α => nothing, :communities => nothing, :internal_λ => nothing, :external_λ => nothing) #allows for parameter-based queries
    for param in keys(db_params_dict)
        if param in fieldnames(typeof(graph_params))
            db_params_dict[param] = getfield(graph_params, param)
        end
    end
    # graph_insert_result = insertGraph(db_filepath, graph_type, graph_params_string, db_params_dict)
    # graph_status = graph_insert_result.status_message
    # graph_row_id = graph_insert_result.insert_row_id

    #prepare and insert data for "sim_params" table. Duplicate rows necessary.
    sim_params_json_str = JSON3.write(sim_params)
    if use_seed == true
        seed_bool = 1
    else
        seed_bool = 0
    end
    # sim_params_insert_result = insertSimParams(db_filepath, sim_params, sim_params_json_str, seed_bool)
    # sim_params_status = sim_params_insert_result.status_message
    # sim_params_row_id = sim_params_insert_result.insert_row_id

    #prepare and insert data for "simulations" table. Duplicate rows necessary.
    adj_matrix_json_str = JSON3.write(Matrix(adjacency_matrix(agent_graph.graph)))
    rng_state = copy(Random.default_rng())
    rng_state_json = JSON3.write(rng_state)

    # simulation_insert_result = insertSimulation(db_filepath, sim_group_id, prev_simulation_uuid, game_row_id, graph_row_id, sim_params_row_id, adj_matrix_json_str, rng_state_json, periods_elapsed)
    # simulation_status = simulation_insert_result.status_message
    # simulation_row_id = simulation_insert_result.insert_row_id

    #create agents list to insert all agents into "agents" table at once
    agents_list = Vector{String}([])
    for agent in agent_graph.agents
        agent_json_str = JSON3.write(agent) #StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable() defined after struct is defined
        push!(agents_list, agent_json_str)
    end
    # agents_status = insertAgents(db_filepath, simulation_row_id, agents_list)




    #push everything to DB (CLEAN THIS UP)

    if nworkers() > 1 #if the simulation is distributed, push to temp sqlite file to be collected later
        # temp_dirpath = createTempDirPath(db_filepath)
        temp_dirpath = distributed_uuid * "/"
        db_filepath = temp_dirpath * "$(myid()).sqlite" #get the current process's ID
    end

    db = SQLite.DB(db_filepath)
    SQLite.busy_timeout(db, 3000)

    game_insert_result = insertGame(db, game_name, game_json_str, payoff_matrix_size)
    #game_status = game_insert_result.status_message
    game_row_id = game_insert_result.insert_row_id

    graph_insert_result = insertGraph(db, graph_type, graph_params_string, db_params_dict)
    #graph_status = graph_insert_result.status_message
    graph_row_id = graph_insert_result.insert_row_id

    sim_params_insert_result = insertSimParams(db, sim_params, sim_params_json_str, seed_bool)
    #sim_params_status = sim_params_insert_result.status_message
    sim_params_row_id = sim_params_insert_result.insert_row_id

    simulation_insert_result = insertSimulation(db, sim_group_id, prev_simulation_uuid, game_row_id, graph_row_id, sim_params_row_id, adj_matrix_json_str, rng_state_json, periods_elapsed)
    #simulation_status = simulation_insert_result.status_message
    simulation_uuid = simulation_insert_result.uuid

    agents_status = insertAgents(db, simulation_uuid, agents_list)

    SQLite.close(db)

    return nothing #(game_status=game_insert_result, graph_status=graph_insert_result, sim_params_status=sim_params_insert_result, simulation_status=simulation_insert_result, agents_status=agents_status)
end


function restoreFromDatabase(db_filepath::String, simulation_id::Integer) #MUST FIX TO USE UUID
    simulation_df = querySimulationForRestore(db_filepath, simulation_id)
    agents_df = queryAgentsForRestore(db_filepath, simulation_id)

    #reproduce SimParams object
    reproduced_sim_params = JSON3.read(simulation_df[1, :sim_params], SimParams)

    #reproduce Game object
    payoff_matrix_size = JSON3.read(simulation_df[1, :payoff_matrix_size], Tuple)
    payoff_matrix_length = payoff_matrix_size[1] * payoff_matrix_size[2]
    reproduced_game = JSON3.read(simulation_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], payoff_matrix_length})

    #reproduced Graph     ###!! dont need to reproduce graph unless the simulation is a pure continuation of 1 long simulation !!###
    reproduced_graph_params = JSON3.read(simulation_df[1, :graph_params], GraphParams)
    reproduced_adj_matrix = JSON3.read(simulation_df[1, :graph_adj_matrix], MMatrix{reproduced_sim_params.number_agents, reproduced_sim_params.number_agents, Int})
    reproduced_graph = SimpleGraph(reproduced_adj_matrix)
    reproduced_meta_graph = MetaGraph(reproduced_graph) #*** MUST CHANGE TO AGENT GRAPH
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