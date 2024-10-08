include("sql.jl")


function db_init(db_info::SQLiteInfo)
    mkpath(dirname(db_info.filepath)) #create the directory path if it doesn't already exist
    execute_init_db(db_info)

    #shouldnt really need to try multiple times here
    # success = false
    # while !success
    #     try
    #         execute_init_db(db_info)
    #         success = true
    #     catch e
    #         if e isa SQLite.SQLiteException

    #             showerror(stdout, e)
    #             sleep(rand(0.1:0.1:4.0))
    #         else
    #             throw(e)
    #         end
    #     end
    # end
end

tempdirpath(db_filepath::String) = rsplit(db_filepath, ".", limit=2)[1] * "/"

function db_init_distributed(distributed_uuid::String) #creates a sparate sqlite file for each worker to prevent database locking conflicts (to later be collected).
    # temp_dirpath = tempdirpath(db_filepath)
    temp_dirpath = distributed_uuid * "/"
    mkdir(temp_dirpath)
    for worker in workers()
        # temp_filepath = temp_dirpath * "$worker.sqlite"
        db_info = SQLiteInfo("temp$(worker)", temp_dirpath * "$worker.sqlite")
        execute_init_db_temp(db_info)
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
            catch e
                if e isa SQLiteException
                    println("An error has been caught in db_collect_distributed():")
                    showerror(stdout, e)
                    sleep(rand(0.1:0.1:4.0))
                else
                    throw(e)
                end
            end
        end
    end
    rm(temp_dirpath, recursive=true) #this is throwing errors on linux server ("directory not empty") due to hidden nsf lock files
end


function db_collect_temp(db_info_master::SQLiteInfo, directory_path::String; cleanup_directory::Bool = false)
    contents = readdir(directory_path)
    for item in contents
        item_path = directory_path * "/" * item
        if isfile(item_path)
            db_info_merger = SQLiteInfo("temp", item_path)
            success = false
            while !success
                try
                    execute_merge_temp(db_info_master, db_info_merger)
                    success = true
                catch e
                    if e isa SQLiteException
                        println("An error has been caught in db_collect_temp():")
                        showerror(stdout, e)
                        sleep(rand(0.1:0.1:4.0))
                    else
                        throw(e)
                    end
                end
            end
            println("[$item_path] merged")
            flush(stdout)
        else
            db_collect_temp(db_info_master, item_path, cleanup_directory=cleanup_directory)
        end
    end
    cleanup_directory && rm(directory_path, recursive=true)
end


function db_insert_group(db_info::SQLiteInfo, description::String)
    # println("Inserting from worker ", myid())
    group_id = nothing
    while isnothing(group_id)
        try
            group_id = execute_insert_sim_group(db_info, description)
        catch e
            if e isa SQLiteException
                println("An error has been caught in db_insert_group():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end
    return group_id
end

function db_insert_game(db_info::SQLiteInfo, game::Game)
    name = name(game)
    game_str = JSON3.write(game)
    size = JSON3.write(size(game)) #NOTE: why JSON3.write instead of string()

    game_id = nothing
    while isnothing(game_id)
        try
            game_id = execute_insert_game(db_info, name, game_str, size)
        catch e
            if e isa SQLiteException
                println("An error has been caught in db_insert_game():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end

    return game_id
end



function sql_dump_graphmodel(graphmodel::GM) where {GM<:GraphModel}
    params = ""
    values = ""
    for param in fieldnames(GM)
        params *= "$param, "
        values *= "$(getfield(graphmodel, param)), "
    end
    params = string(rstrip(params, [' ', ',']))
    if !isempty(params)
        params = ", " * params
    end
    values = string(rstrip(values, [' ', ',']))
    if !isempty(values)
        values = ", " * values
    end
    return (params, values)
end

function db_insert_graphmodel(db_info::SQLiteInfo, graphmodel::GraphModel)
    display = displayname(graphmodel)
    type = type(graphmodel)
    graphmodel_str = JSON3.write(graphmodel)
    # db_params_dict = Dict{Symbol, Any}(:λ => nothing, :β => nothing, :α => nothing, :blocks => nothing, :p_in => nothing, :p_out => nothing) #allows for parameter-based queries
    
    # for param in keys(db_params_dict)
    #     if param in fieldnames(typeof(graph_model))
    #         db_params_dict[param] = getfield(graph_model, param)
    #     end
    # end
    params_str, values_str = sql_dump_graphmodel(graphmodel)

    graphmodel_id = nothing
    while isnothing(graph_id)
        try
            graphmodel_id = execute_insert_graphmodel(db_info, display, type, graphmodel_str, params_str, values_str)
        catch e
            if e isa SQLiteException
                println("An error has been caught in db_insert_graphmodel():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end

    return graphmodel_id
end

function db_insert_simparams(db_info::SQLiteInfo, simparams::SimParams, use_seed::Bool)
    simparams_json_str = JSON3.write(simparams)
    seed_bool = Int(use_seed)

    simparams_id = nothing
    while isnothing(simparams_id)
        try
            simparams_id = execute_insert_simparams(db_info, simparams, simparams_json_str, seed_bool)
        catch e
            if e isa SQLiteException
                println("An error has been caught in db_insert_simparams():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end

    return simparams_id
end

function db_insert_startingcondition(db_info::SQLiteInfo, startingcondition::StartingCondition)
    startingcondition_json_str = JSON3.write(typeof(startingcondition)(startingcondition)) #generates a "raw" starting condition object for the database
    name = name(startingcondition)

    startingcondition_id = nothing
    while startingcondition_id === nothing
        try
            startingcondition_id = execute_insert_startingcondition(db_info, name, startingcondition_json_str)
        catch
            if e isa SQLiteException
                println("An error has been caught in db_insert_startingcondition():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end

    return startingcondition_id
end

function db_insert_stoppingcondition(db_info::SQLiteInfo, stoppingcondition::StoppingCondition)
    stoppingcondition_json_str = JSON3.write(typeof(stoppingcondition)(stoppingcondition)) #generates a "raw" stopping condition object for the database
    name = name(stoppingcondition)

    stoppingcondition_id = nothing
    while isnothing(stoppingcondition_id)
        try
            stoppingcondition_id::Int = execute_insert_stoppingcondition(db_info, name, stoppingcondition_json_str)
            return stoppingcondition_id
        catch
            if e isa SQLiteException
                println("An error has been caught in db_insert_stoppingcondition():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end
end



function db_insert_model(db_info::SQLiteInfo, model::SimModel, use_seed::Bool)
    model_game = game(model)
    game_name = displayname(model_game)
    game_str = JSON3.write(model_game)
    game_size = JSON3.write(size(model_game)) #NOTE: why JSON3.write instead of string()

    model_graphmodel = graphmodel(model)
    graphmodel_display = displayname(model_graphmodel)
    graphmodel_type = type(model_graphmodel)
    graphmodel_str = JSON3.write(model_graphmodel)
    graphmodel_params_str, graphmodel_values_str = sql_dump_graphmodel(model_graphmodel)

    model_simparams = simparams(model)
    simparams_str = JSON3.write(model_simparams)
    seed_bool = Int(use_seed)

    model_startingcondition = startingcondition(model)
    startingcondition_str = JSON3.write(typeof(model_startingcondition)(model_startingcondition)) #generates a "raw" starting condition object for the database
    startingcondition_name = displayname(model_startingcondition)

    model_stoppingcondition = stoppingcondition(model)
    stoppingcondition_str = JSON3.write(typeof(model_stoppingcondition)(model_stoppingcondition)) #generates a "raw" stopping condition object for the database
    stoppingcondition_name = displayname(model_stoppingcondition)

    println(graphmodel_params_str)
    println(graphmodel_values_str)
    # model_id = nothing
    # while isnothing(model_id)
        # try
            model_id = execute_insert_model(db_info,
                                            game_name, game_str, game_size,
                                            graphmodel_display, graphmodel_type, graphmodel_str, graphmodel_params_str, graphmodel_values_str,
                                            model_simparams, simparams_str, seed_bool,
                                            startingcondition_name, startingcondition_str,
                                            stoppingcondition_name, stoppingcondition_str)
    #     catch e
    #         if e isa SQLiteException
    #             println("An error has been caught in db_insert_model():")
    #             showerror(stdout, e)
    #             sleep(rand(0.1:0.1:4.0))
    #         else
    #             throw(e)
    #         end
    #     end
    # end

    return model_id
end



function db_insert_simulation(db_info::SQLiteInfo, sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, model_id::Integer, agentgraph::AgentGraph, periods_elapsed::Integer, distributed_uuid::Union{String, Nothing} = nothing)
    #prepare simulation to be inserted
    adj_matrix_json_str = JSON3.write(Matrix(adjacency_matrix(graph(agentgraph))))
    rng_state = copy(Random.default_rng())
    rng_state_json = JSON3.write(rng_state)

    #prepare agents to be inserted
    agents_list = Vector{String}([])
    for agent in agents(agentgraph)
        agent_json_str = JSON3.write(agent) #StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable() defined after struct is defined
        push!(agents_list, agent_json_str)
    end


    if nworkers() > 1 #if the simulation is distributed, push to temp sqlite file to be collected later
        # temp_dirpath = tempdirpath(db_filepath)
        temp_dirpath = distributed_uuid * "/"
        # db_filepath = temp_dirpath * "$(myid()).sqlite" #get the current process's ID
        db_info = SQLiteInfo("temp$(myid())", temp_dirpath * "$(myid()).sqlite")
    end


    simulation_uuid = nothing
    while isnothing(simulation_uuid)
        try
            simulation_uuid = execute_insert_simulation(db_info, sim_group_id, prev_simulation_uuid, model_id, adj_matrix_json_str, rng_state_json, periods_elapsed, agents_list)
            #simulation_status = simulation_insert_result.status_message
            # simulation_uuid = simulation_insert_result.simulation_uuid
        catch e
            if e isa SQLiteException
                println("An error has been caught in db_insert_simulation():")
                showerror(stdout, e)
                sleep(rand(0.1:0.1:4.0))
            else
                throw(e)
            end
        end
    end
    return simulation_uuid
end


# function db_checkpoint(db_info::SQLiteInfo, model::SimModel)


# #NOTE: FIX
# function db_restore_model(db_filepath::String, simulation_id::Integer) #MUST FIX TO USE UUID
#     simulation_df = execute_query_simulations_for_restore(db_filepath, simulation_id)
#     agents_df = execute_query_agents_for_restore(db_filepath, simulation_id)

#     #reproduce SimParams object
#     reproduced_sim_params = JSON3.read(simulation_df[1, :sim_params], SimParams)

#     #reproduce Game object
#     payoff_matrix_size = JSON3.read(simulation_df[1, :payoff_matrix_size], Tuple)
#     payoff_matrix_length = payoff_matrix_size[1] * payoff_matrix_size[2]
#     reproduced_game = JSON3.read(simulation_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], payoff_matrix_length})

#     #reproduced Graph     ###!! dont need to reproduce graph unless the simulation is a pure continuation of 1 long simulation !!###
#     reproduced_graph_model = JSON3.read(simulation_df[1, :graph_model], GraphModel)
#     reproduced_adj_matrix = JSON3.read(simulation_df[1, :graph_adj_matrix], MMatrix{reproduced_sim_params.number_agents, reproduced_sim_params.number_agents, Int})
#     reproduced_graph = SimpleGraph(reproduced_adj_matrix)
#     reproduced_meta_graph = MetaGraph(reproduced_graph) #*** MUST CHANGE TO AGENT GRAPH
#     for vertex in vertices(reproduced_meta_graph)
#         agent = JSON3.read(agents_df[vertex, :agent], Agent)
#         set_prop!(reproduced_meta_graph, vertex, :agent, agent)
#     end

#     #restore RNG to previous state
#     if simulation_df[1, :use_seed] == 1
#         seed_bool = true
#         reproduced_rng_state = JSON3.read(simulation_df[1, :rng_state], Random.Xoshiro)
#         copy!(Random.default_rng(), reproduced_rng_state)
#     else
#         seed_bool = false
#     end
#     return (game=reproduced_game, sim_params=reproduced_sim_params, graph_model=reproduced_graph_model, meta_graph=reproduced_meta_graph, use_seed=seed_bool, periods_elapsed=simulation_df[1, :periods_elapsed], sim_group_id=simulation_df[1, :sim_group_id])
# end