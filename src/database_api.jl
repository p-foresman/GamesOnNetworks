function db_init(db_filepath::String)
    success = false
    while !success
        try
            execute_init_full(db_filepath)
            success = true
        catch
            sleep(rand(0.1:0.1:4.0))
        end
    end
end

tempdirpath(db_filepath::String) = rsplit(db_filepath, ".", limit=2)[1] * "/"

function db_init_distributed(distributed_uuid::String) #creates a sparate sqlite file for each worker to prevent database locking conflicts (to later be collected).
    # temp_dirpath = tempdirpath(db_filepath)
    temp_dirpath = distributed_uuid * "/"
    mkdir(temp_dirpath)
    for worker in workers()
        temp_filepath = temp_dirpath * "$worker.sqlite"
        execute_init_temp(temp_filepath)
    end
    return nothing
end


#NOTE: probably don't actually need this function (can be handled by the following function)
function db_collect_distributed(db_filepath::String, distributed_uuid::String) #collects distributed db files into the db_filepath 
    # temp_dirpath = tempdirpath(db_filepath)
    temp_dirpath = distributed_uuid * "/"
    for worker in workers()
        temp_filepath = temp_dirpath * "$worker.sqlite"
        success = false
        while !success #should i create a database lock before iterating through workers?
            try
                execute_merge_temp(db_filepath, temp_filepath)
                # rm(temp_filepath)
                success = true
            catch
                sleep(rand(0.1:0.1:4.0))
            end
        end
    end
    rm(temp_dirpath, recursive=true) #this is throwing errors on linux server ("directory not empty")
end


function db_collect_temp(db_filepath::String, directory_path::String; cleanup_directory::Bool = false)
    contents = readdir(directory_path)
    for item in contents
        item_path = directory_path * "/" * item
        if isfile(item_path)
            success = false
            while !success
                try
                    execute_merge_temp(db_filepath, item_path)
                    success = true
                catch
                    sleep(rand(0.1:0.1:4.0))
                end
            end
        else
            db_collect_temp(db_filepath, item_path, cleanup_directory=cleanup_directory)
        end
    end
    cleanup_directory && rm(directory_path, recursive=true)
end


db_insert_sim_group(db_filepath::String, description::String) = execute_insert_sim_group(db_filepath, description)

function db_insert_game(db_filepath::String, game::Game)
    game_name = game.name
    game_json_str = JSON3.write(game)
    payoff_matrix_size = JSON3.write(size(game.payoff_matrix))

    game_row_id = nothing
    while game_row_id === nothing
        try
            game_insert_result = execute_insert_game(db_filepath, game_name, game_json_str, payoff_matrix_size)
            game_row_id = game_insert_result.insert_row_id
        catch
            sleep(rand(0.1:0.1:4.0))
        end
    end

    #game_status = game_insert_result.status_message

    return game_row_id
end

function db_insert_graph(db_filepath::String, graph_params::GraphParams)
    graph_type = displayname(graph_params)
    graph_params_string = JSON3.write(graph_params)
    db_params_dict = Dict{Symbol, Any}(:λ => nothing, :κ => nothing, :β => nothing, :α => nothing, :d => nothing, :communities => nothing, :internal_λ => nothing, :external_λ => nothing) #allows for parameter-based queries
    
    for param in keys(db_params_dict)
        if param in fieldnames(typeof(graph_params))
            db_params_dict[param] = getfield(graph_params, param)
        end
    end

    graph_row_id = nothing
    while graph_row_id === nothing
        try
            graph_insert_result = execute_insert_graph(db_filepath, graph_type, graph_params_string, db_params_dict)
            #graph_status = graph_insert_result.status_message
            graph_row_id = graph_insert_result.insert_row_id
        catch
            sleep(rand(0.1:0.1:4.0))
        end
    end

    return graph_row_id
end

function db_insert_sim_params(db_filepath::String, sim_params::SimParams, use_seed::Bool)
    sim_params_json_str = JSON3.write(sim_params)

    if use_seed == true
        seed_bool = 1
    else
        seed_bool = 0
    end

    sim_params_row_id = nothing
    while sim_params_row_id === nothing
        try
            sim_params_insert_result = execute_insert_sim_params(db_filepath, sim_params, sim_params_json_str, seed_bool)
            #sim_params_status = sim_params_insert_result.status_message
            sim_params_row_id = sim_params_insert_result.insert_row_id
        catch
            sleep(rand(0.1:0.1:4.0))
        end
    end

    return sim_params_row_id
end

function db_insert_starting_condition(db_filepath::String, starting_condition::StartingCondition)
    starting_condition_json_str = JSON3.write(starting_condition)

    starting_condition_row_id = nothing
    while starting_condition_row_id === nothing
        try
            starting_condition_insert_result = execute_insert_starting_condition(db_filepath, starting_condition.name, starting_condition_json_str)
            #starting_condition_status = starting_condition_insert_result.status_message
            starting_condition_row_id = starting_condition_insert_result.insert_row_id
        catch
            sleep(rand(0.1:0.1:4.0))
        end
    end

    return starting_condition_row_id
end

function db_insert_stopping_condition(db_filepath::String, stopping_condition::StoppingCondition)
    stopping_condition_json_str = JSON3.write(stopping_condition)

    stopping_condition_row_id = nothing
    while stopping_condition_row_id === nothing
        try
            stopping_condition_insert_result = execute_insert_stopping_condition(db_filepath, stopping_condition.name, stopping_condition_json_str)
            #stopping_condition_status = stopping_condition_insert_result.status_message
            stopping_condition_row_id = stopping_condition_insert_result.insert_row_id
        catch
            sleep(rand(0.1:0.1:4.0))
        end
    end

    return stopping_condition_row_id
end

function db_insert_simulation_with_agents(db_filepath::String, sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, db_id_tuple::NamedTuple{(:game_id, :graph_id, :sim_params_id, :starting_condition_id, :stopping_condition_id), NTuple{5, Int}}, agent_graph::AgentGraph, periods_elapsed::Integer, distributed_uuid::Union{String, Nothing} = nothing)
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
        # temp_dirpath = tempdirpath(db_filepath)
        temp_dirpath = distributed_uuid * "/"
        db_filepath = temp_dirpath * "$(myid()).sqlite" #get the current process's ID
    end


    simulation_insert_result = nothing
    while simulation_insert_result === nothing
        try
            simulation_insert_result = execute_insert_simulation_with_agents(db_filepath, sim_group_id, prev_simulation_uuid, db_id_tuple, adj_matrix_json_str, rng_state_json, periods_elapsed, agents_list)
            #simulation_status = simulation_insert_result.status_message
            # simulation_uuid = simulation_insert_result.simulation_uuid
        catch
            sleep(rand(0.1:0.1:4.0))
        end
    end
    return simulation_insert_result
end


function db_id_tuple(model::SimModel, db_filepath::String; use_seed::Bool = false)
    db_id_tuple::NamedTuple{(:game_id, :graph_id, :sim_params_id, :starting_condition_id, :stopping_condition_id), NTuple{5, Int}} = (
                    game_id = db_insert_game(db_filepath, model.game),
                    graph_id = db_insert_graph(db_filepath, model.graph_params),
                    sim_params_id = db_insert_sim_params(db_filepath, model.sim_params, use_seed),
                    starting_condition_id = db_insert_starting_condition(db_filepath, model.starting_condition),
                    stopping_condition_id = db_insert_stopping_condition(db_filepath, model.stopping_condition)
                    )
    return db_id_tuple
end

#taken care of in plotting.jl
# function pullTimeSeriesDataFromDB(db_filepath::String; sim_group_id::Integer)
#     sim_info_df, agent_df = querySimulationsForTimeSeries(db_filepath, sim_group_id=sim_group_id)
#     agent_dict = OrderedDict()
#     for row in eachrow(agent_df)
#         if !haskey(agent_dict, row.periods_elapsed)
#             agent_dict[row.periods_elapsed] = []
#         end
#         agent = JSON3.read(row.agent, Agent)
#         agent_memory = agent.memory
#         push!(agent_dict[row.periods_elapsed], agent_memory)
#     end
#     return sim_info_df, agent_dict
# end


################## old method ######################


# function pushToDatabase(db_filepath::String, sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, game::Game, sim_params::SimParams, graph_params::GraphParams, agent_graph::AgentGraph, periods_elapsed::Integer, use_seed::Bool, distributed_uuid::Union{String, Nothing} = nothing)
#     #prepare and instert data for "games" table. No duplicate rows.
#     game_name = game.name
#     game_json_str = JSON3.write(game)
#     payoff_matrix_size = JSON3.write(size(game.payoff_matrix))
#     # game_insert_result = insertGame(db_filepath, game_name, game_json_str, payoff_matrix_size)
#     # game_status = game_insert_result.status_message
#     # game_row_id = game_insert_result.insert_row_id

#     #prepare and insert data for "graphs" table. No duplicate rows.
#     graph_type = displayname(graph_params)
#     graph_params_string = JSON3.write(graph_params)
#     db_params_dict = Dict{Symbol, Any}(:λ => nothing, :κ => nothing, :β => nothing, :α => nothing, :d => nothing, :communities => nothing, :internal_λ => nothing, :external_λ => nothing) #allows for parameter-based queries
#     for param in keys(db_params_dict)
#         if param in fieldnames(typeof(graph_params))
#             db_params_dict[param] = getfield(graph_params, param)
#         end
#     end
#     # graph_insert_result = insertGraph(db_filepath, graph_type, graph_params_string, db_params_dict)
#     # graph_status = graph_insert_result.status_message
#     # graph_row_id = graph_insert_result.insert_row_id

#     #prepare and insert data for "sim_params" table. Duplicate rows necessary.
#     sim_params_json_str = JSON3.write(sim_params)
#     if use_seed == true
#         seed_bool = 1
#     else
#         seed_bool = 0
#     end
#     # sim_params_insert_result = insertSimParams(db_filepath, sim_params, sim_params_json_str, seed_bool)
#     # sim_params_status = sim_params_insert_result.status_message
#     # sim_params_row_id = sim_params_insert_result.insert_row_id

#     #prepare and insert data for "simulations" table. Duplicate rows necessary.
#     adj_matrix_json_str = JSON3.write(Matrix(adjacency_matrix(agent_graph.graph)))
#     rng_state = copy(Random.default_rng())
#     rng_state_json = JSON3.write(rng_state)

#     # simulation_insert_result = insertSimulation(db_filepath, sim_group_id, prev_simulation_uuid, game_row_id, graph_row_id, sim_params_row_id, adj_matrix_json_str, rng_state_json, periods_elapsed)
#     # simulation_status = simulation_insert_result.status_message
#     # simulation_row_id = simulation_insert_result.insert_row_id

#     #create agents list to insert all agents into "agents" table at once
#     agents_list = Vector{String}([])
#     for agent in agent_graph.agents
#         agent_json_str = JSON3.write(agent) #StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable() defined after struct is defined
#         push!(agents_list, agent_json_str)
#     end
#     # agents_status = insertAgents(db_filepath, simulation_row_id, agents_list)




#     #push everything to DB (CLEAN THIS UP)

#     if nworkers() > 1 #if the simulation is distributed, push to temp sqlite file to be collected later
#         # temp_dirpath = tempdirpath(db_filepath)
#         temp_dirpath = distributed_uuid * "/"
#         db_filepath = temp_dirpath * "$(myid()).sqlite" #get the current process's ID
#     end

#     db = SQLite.DB(db_filepath)
#     SQLite.busy_timeout(db, 3000)

#     game_insert_result = insertGame(db, game_name, game_json_str, payoff_matrix_size)
#     #game_status = game_insert_result.status_message
#     game_row_id = game_insert_result.insert_row_id

#     graph_insert_result = insertGraph(db, graph_type, graph_params_string, db_params_dict)
#     #graph_status = graph_insert_result.status_message
#     graph_row_id = graph_insert_result.insert_row_id

#     sim_params_insert_result = insertSimParams(db, sim_params, sim_params_json_str, seed_bool)
#     #sim_params_status = sim_params_insert_result.status_message
#     sim_params_row_id = sim_params_insert_result.insert_row_id

#     simulation_insert_result = insertSimulation(db, sim_group_id, prev_simulation_uuid, game_row_id, graph_row_id, sim_params_row_id, adj_matrix_json_str, rng_state_json, periods_elapsed)
#     #simulation_status = simulation_insert_result.status_message
#     simulation_uuid = simulation_insert_result.uuid

#     agents_status = insertAgents(db, simulation_uuid, agents_list)

#     SQLite.close(db)

#     return nothing #(game_status=game_insert_result, graph_status=graph_insert_result, sim_params_status=sim_params_insert_result, simulation_status=simulation_insert_result, agents_status=agents_status)
# end

#NOTE: FIX
function db_restore_model(db_filepath::String, simulation_id::Integer) #MUST FIX TO USE UUID
    simulation_df = execute_query_simulations_for_restore(db_filepath, simulation_id)
    agents_df = execute_query_agents_for_restore(db_filepath, simulation_id)

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