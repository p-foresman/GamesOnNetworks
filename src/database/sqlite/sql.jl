using SQLite

const SQLiteDB = SQLite.DB
const SQL = String

function DB(db_info::SQLiteInfo; busy_timeout::Int=3000)
    db = SQLiteDB(db_info.filepath)
    SQLite.busy_timeout(db, busy_timeout)
    return db
end
db_begin_transaction(db::SQLiteDB) = SQLite.transaction(db) #does have a default mode that may be useful to change
db_execute(db::SQLiteDB, sql::SQL) = DBInterface.execute(db, sql)
db_query(db::SQLiteDB, sql::SQL) = DataFrame(db_execute(db, sql))
db_commit_transaction(db::SQLiteDB) = SQLite.commit(db)
db_close(db::SQLiteDB) = SQLite.close(db)

function sql_create_games_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS games
    (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        game TEXT NOT NULL,
        payoff_matrix_size TEXT NOT NULL,
        UNIQUE(name, game)
    );
    """
end

function sql_create_graphmodels_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS graphmodels
    (
        id INTEGER PRIMARY KEY,
        display TEXT NOT NULL,
        type TEXT NOT NULL,
        graphmodel TEXT NOT NULL,
        λ REAL DEFAULT NULL,
        β REAL DEFAULT NULL,
        α REAL DEFAULT NULL,
        blocks INTEGER DEFAULT NULL,
        p_in REAL DEFAULT NULL,
        p_out REAL DEFAULT NULL,
        UNIQUE(graphmodel)
    );
    """
end

function sql_create_simparams_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS simparams
    (
        id INTEGER PRIMARY KEY,
        number_agents INTEGER NOT NULL,
        memory_length INTEGER NOT NULL,
        error REAL NOT NULL,
        simparams TEXT NOT NULL,
        use_seed BOOLEAN NOT NULL,
        UNIQUE(simparams, use_seed),
        CHECK (use_seed in (0, 1))
    );
    """
end

function sql_create_startingconditions_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS startingconditions
    (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        startingcondition TEXT NOT NULL,
        UNIQUE(name, startingcondition)
    );
    """
end

function sql_create_stoppingconditions_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS stoppingconditions
    (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        stoppingcondition TEXT NOT NULL,
        UNIQUE(name, stoppingcondition)
    );
    """
end

function sql_create_models_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS models
    (
        id INTEGER PRIMARY KEY,
        game_id INTEGER NOT NULL,
        graphmodel_id INTEGER NOT NULL,
        simparams_id INTEGER NOT NULL,
        startingcondition_id INTEGER NOT NULL,
        stoppingcondition_id INTEGER NOT NULL,
        FOREIGN KEY (game_id)
            REFERENCES games (game_id)
            ON DELETE CASCADE,
        FOREIGN KEY (graphmodel_id)
            REFERENCES graphmodels (id)
            ON DELETE CASCADE,
        FOREIGN KEY (simparams_id)
            REFERENCES simparams (id)
            ON DELETE CASCADE,
        FOREIGN KEY (startingcondition_id)
            REFERENCES startingconditions (id)
            ON DELETE CASCADE,
        FOREIGN KEY (stoppingcondition_id)
            REFERENCES stoppingconditions (id)
            ON DELETE CASCADE,
        UNIQUE(game_id, graphmodel_id, simparams_id, startingcondition_id, stoppingcondition_id)
    );
    """
end

function sql_create_groups_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS groups
    (
        id INTEGER PRIMARY KEY,
        description TEXT DEFAULT NULL,
        UNIQUE(description)
    );
    """
end

function sql_create_simulations_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS simulations
    (
        uuid TEXT PRIMARY KEY,
        group_id INTEGER DEFAULT NULL,
        prev_simulation_uuid TEXT DEFAULT NULL,
        model_id INTEGER NOT NULL,
        graph_adj_matrix TEXT DEFAULT NULL,
        rng_state TEXT NOT NULL,
        periods_elapsed INTEGER NOT NULL,
        FOREIGN KEY (group_id)
            REFERENCES groups (id)
            ON DELETE CASCADE,
        FOREIGN KEY (prev_simulation_uuid)
            REFERENCES simulations (simulation_uuid),
        FOREIGN KEY (model_id)
            REFERENCES models (id),
        UNIQUE(uuid)
    );
    """
end


function sql_create_agents_table(::SQLiteInfo)
    """
    CREATE TABLE IF NOT EXISTS agents
    (
        id INTEGER PRIMARY KEY,
        simulation_uuid TEXT NOT NULL,
        agent TEXT NOT NULL,
        FOREIGN KEY (simulation_uuid)
            REFERENCES simulations (simulation_uuid)
            ON DELETE CASCADE
    );
    """
end


function execute_init_db(db_info::SQLiteInfo)
    db = DB(db_info)
    db_begin_transaction(db)
    db_execute(db, sql_create_games_table(db_info))
    db_execute(db, sql_create_graphmodels_table(db_info))
    db_execute(db, sql_create_simparams_table(db_info))
    db_execute(db, sql_create_startingconditions_table(db_info))
    db_execute(db, sql_create_stoppingconditions_table(db_info))
    db_execute(db, sql_create_models_table(db_info))
    db_execute(db, sql_create_groups_table(db_info))
    db_execute(db, sql_create_simulations_table(db_info))
    db_execute(db, sql_create_agents_table(db_info))
    db_commit_transaction(db)
    db_close(db)
end

#this DB only needs tables for simulations and agents. These will be collected into the master DB later
function execute_init_db_temp(db_info::SQLiteInfo)
    db = DB(db_info)
    db_begin_transaction(db)
    db_execute(db, sql_create_simulations_table(db_info))
    db_execute(db, sql_create_agents_table(db_info))
    db_commit_transaction(db)
    db_close(db)
end


function sql_insert_game(name::String, game_str::String, payoff_matrix_size::String)
    """
    INSERT OR IGNORE INTO games
    (
        name,
        game,
        payoff_matrix_size
    )
    VALUES
    (
        '$name',
        '$game_str',
        '$payoff_matrix_size'
    )
    ON CONFLICT (name, game) DO UPDATE
        SET name = games.name
    RETURNING id;
    """
end

function sql_insert_graphmodel(display::String, type::String, graphmodel_str::String, params_str::String, values_str::String)
    # insert_string_columns = "display, type, graphmodel, "
    # insert_string_values = "'$display', '$type', '$graphmodel_str', "
    # for (param, value) in db_graph_params_dict
    #     if value !== nothing
    #         insert_string_columns *= "'$param', "
    #         insert_string_values *= "$value, "
    #     end
    # end
    # insert_string_columns = rstrip(insert_string_columns, [' ', ',']) #strip off the comma and space at the end of the string
    # insert_string_values = rstrip(insert_string_values, [' ', ','])
    """
    INSERT OR IGNORE INTO graphmodels
    (
        display,
        type,
        graphmodel
        $params_str
    )
    VALUES
    (   
        '$display',
        '$type',
        '$graphmodel_str'
        $values_str
    )
    ON CONFLICT (graphmodel) DO UPDATE
        SET type = graphmodels.type
    RETURNING id;
    """
end

function sql_insert_simparams(simparams::SimParams, simparams_str::String, use_seed::Integer)
    """
    INSERT OR IGNORE INTO simparams
    (
        number_agents,
        memory_length,
        error,
        simparams,
        use_seed
    )
    VALUES
    (
        $(number_agents(simparams)),
        $(memory_length(simparams)),
        $(error_rate(simparams)),
        '$simparams_str',
        $use_seed
    )
    ON CONFLICT (simparams, use_seed) DO UPDATE
        SET use_seed = simparams.use_seed
    RETURNING id;
    """
end

function sql_insert_startingcondition(name::String, startingcondition_str::String)
    """
    INSERT OR IGNORE INTO startingconditions
    (
        name,
        startingcondition
    )
    VALUES
    (
        '$name',
        '$(startingcondition_str)'
    )
    ON CONFLICT (name, startingcondition) DO UPDATE
        SET name = startingconditions.name
    RETURNING id;
    """
end

function sql_insert_stoppingcondition(name::String, stoppingcondition_str::String)
    """
    INSERT OR IGNORE INTO stoppingconditions
    (
        name,
        stoppingcondition
    )
    VALUES
    (
        '$name',
        '$(stoppingcondition_str)'
    )
    ON CONFLICT (name, stoppingcondition) DO UPDATE
        SET name = stoppingconditions.name
    RETURNING id;
    """
end

function sql_insert_model(game_id::Integer, graphmodel_id::Integer, simparams_id::Integer, startingcondition_id::Integer, stoppingcondition_id::Integer)
   """
    INSERT OR IGNORE INTO models
    (
        game_id,
        graphmodel_id,
        simparams_id,
        startingcondition_id,
        stoppingcondition_id
    )
    VALUES
    (
        $game_id,
        $graphmodel_id,
        $simparams_id,
        $startingcondition_id,
        $stoppingcondition_id
    )
    ON CONFLICT (game_id, graphmodel_id, simparams_id, startingcondition_id, stoppingcondition_id) DO UPDATE
        SET game_id = models.game_id
    RETURNING id;
    """ 
end

function execute_insert_game(db::SQLiteDB, name::String, game_str::String, payoff_matrix_size::String)
    id::Int = db_query(db, sql_insert_game(name, game_str, payoff_matrix_size))[1, :id]
    return id
end

function execute_insert_graphmodel(db::SQLiteDB, display::String, type::String, graphmodel_str::String, params_str::String, values_str::String)
    id::Int = db_query(db, sql_insert_graphmodel(display, type, graphmodel_str, params_str, values_str))[1, :id]
    return id
end

function execute_insert_simparams(db::SQLiteDB, simparams::SimParams, simparams_str::String, use_seed::Integer)
    id::Int = db_query(db, sql_insert_simparams(simparams, simparams_str, use_seed))[1, :id]
    return id
end

function execute_insert_startingcondition(db::SQLiteDB, name::String, startingcondition_str::String)
    id::Int = db_query(db, sql_insert_startingcondition(name, startingcondition_str))[1, :id]
    return id
end

function execute_insert_stoppingcondition(db::SQLiteDB, name::String, stoppingcondition_str::String)
    id::Int = db_query(db, sql_insert_stoppingcondition(name, stoppingcondition_str))[1, :id]
    return id
end

#dont want to be able to insert a model without all the other components (although could be useful to create new models in the database to choose from?)
# function execute_insert_model(db::SQLiteDB, game_id::Integer, graphmodel_id::Integer, simparams_id::Integer, startingcondition_id::Integer, stoppingcondition_id::Integer)
#     id::Int = db_query(db, sql_insert_model(game_id, graphmodel_id, simparams_id, startingcondition_id, stoppingcondition_id))[1, :id]
#     return id
# end

function execute_insert_model(db_info::SQLiteInfo,
                            game_name::String, game_str::String, payoff_matrix_size::String,
                            graphmodel_display::String, graphmodel_type::String, graphmodel_str::String, graphmodel_params_str::String, graphmodel_values_str::String, #NOTE: should try to make all parameters String typed so they can be plugged right into sql
                            simparams::SimParams, simparams_str::String, use_seed::Integer,
                            startingcondition_name::String, startingcondition_str::String,
                            stoppingcondition_name::String, stoppingcondition_str::String)


    db = DB(db_info)
    db_begin_transaction(db)
    game_id = execute_insert_game(db, game_name, game_str, payoff_matrix_size)
    graphmodel_id = execute_insert_graphmodel(db, graphmodel_display, graphmodel_type, graphmodel_str, graphmodel_params_str, graphmodel_values_str)
    simparams_id = execute_insert_simparams(db, simparams, simparams_str, use_seed)
    startingcondition_id = execute_insert_startingcondition(db, startingcondition_name, startingcondition_str)
    stoppingcondition_id = execute_insert_stoppingcondition(db, stoppingcondition_name, stoppingcondition_str)
    # id = execute_insert_model(db, game_id, graphmodel_id, simparams_id, startingcondition_id, stoppingcondition_id)
    id::Int = db_query(db, sql_insert_model(game_id, graphmodel_id, simparams_id, startingcondition_id, stoppingcondition_id))[1, :id]
    db_commit_transaction(db)
    db_close(db)
    return id
end


####################################################



function sql_insert_group(description::String)
    """
    INSERT OR IGNORE INTO groups
    (
        description
    )
    VALUES
    (
        '$description'
    )
    ON CONFLICT (description) DO UPDATE
        SET description = groups.description
    RETURNING id;
    """
end



function execute_insert_group(db_info::SQLiteInfo, description::String)
    db = DB(db_info)
    id::Int = db_query(db, sql_insert_group(description))[1, :id]
    db_close(db)
    return id
end


function sql_insert_simulation(uuid::String, group_id::String, prev_simulation_uuid::String, model_id::Integer, graph_adj_matrix_str::String, rng_state::String, periods_elapsed::Integer)
    """
    INSERT INTO simulations
    (
        uuid,
        group_id,
        prev_simulation_uuid,
        model_id,
        graph_adj_matrix,
        rng_state,
        periods_elapsed
    )
    VALUES
    (
        '$uuid',
        $group_id,
        '$prev_simulation_uuid',
        $model_id,
        '$graph_adj_matrix_str',
        '$rng_state',
        $periods_elapsed
    );
    ON CONFLICT () DO UPDATE
        SET group_id = simulations.group_id
    RETURNING uuid
    """
end

function sql_insert_agents(agent_values_string::String) #kind of a cop-out parameter but fine for now
    """
    INSERT INTO agents
    (
        simulation_uuid,
        agent
    )
    VALUES
        $agent_values_string;
    """
end

function execute_insert_simulation(db_info::SQLiteInfo, group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, model_id::Integer, graph_adj_matrix_str::String, rng_state::String, periods_elapsed::Integer, agent_list::Vector{String})
    uuid = "$(uuid4())"
    
    #prepare simulation SQL
    group_id = isnothing(group_id) ? "NULL" : string(group_id)
    isnothing(prev_simulation_uuid) ?  prev_simulation_uuid = "NULL" : nothing

    #prepare agents SQL
    agent_values_string = "" #construct a values string to insert multiple agents into db table
    for agent in agent_list
        agent_values_string *= "('$uuid', '$agent'), "
    end
    agent_values_string = string(rstrip(agent_values_string, [' ', ',']))

    db = DB(db_info)
    db_begin_transaction(db)
    db_execute(db, sql_insert_simulation(uuid, group_id, prev_simulation_uuid, model_id, graph_adj_matrix_str, rng_state, periods_elapsed))
    db_execute(db, sql_insert_agents(agent_values_string))
    db_commit_transaction(db)
    db_close(db)
    return uuid
end


function execute_query_games(db_info::SQLiteInfo, game_id::Integer)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM games
                                        WHERE game_id = $game_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_graphmodels(db_info::SQLiteInfo, graph_id::Integer)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM graphmodels
                                        WHERE graph_id = $graph_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_sim_params(db_info::SQLiteInfo, sim_params_id::Integer)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM sim_params
                                        WHERE sim_params_id = $sim_params_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_starting_conditions(db_info::SQLiteInfo, starting_condition_id::Integer)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM starting_conditions
                                        WHERE starting_condition_id = $starting_condition_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_stopping_conditions(db_info::SQLiteInfo, stopping_condition_id::Integer)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM stopping_conditions
                                        WHERE stopping_condition_id = $stopping_condition_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_sim_groups(db_info::SQLiteInfo, group_id::Integer)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM sim_groups
                                        WHERE group_id = $group_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_simulations(db_info::SQLiteInfo, simulation_id::Integer)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM simulations
                                        WHERE simulation_id = $simulation_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_agents(db_info::SQLiteInfo, simulation_id::Integer)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM agents
                                        WHERE simulation_id = $simulation_id
                                        ORDER BY agent_id ASC;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_simulations_for_restore(db_info::SQLiteInfo, simulation_id::Integer)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT
                                            simulations.simulation_id,
                                            simulations.group_id,
                                            sim_params.sim_params,
                                            sim_params.use_seed,
                                            simulations.rng_state,
                                            simulations.periods_elapsed,
                                            simulations.graph_adj_matrix,
                                            graphmodels.graph_params,
                                            games.game,
                                            games.payoff_matrix_size,
                                            starting_conditions.starting_condition,
                                            stopping_conditions.stopping_condition
                                        FROM simulations
                                        INNER JOIN games USING(game_id)
                                        INNER JOIN graphmodels USING(graph_id)
                                        INNER JOIN sim_params USING(sim_params_id)
                                        INNER JOIN starting_conditions USING(starting_condition_id)
                                        INNER JOIN stopping_conditions USING(stopping_condition_id)
                                        WHERE simulations.simulation_id = $simulation_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_query_agents_for_restore(db_info::SQLiteInfo, simulation_id::Integer)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT agent
                                        FROM agents
                                        WHERE simulation_id = $simulation_id
                                        ORDER BY agent_id ASC;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end


#NOTE: FIX
# function querySimulationsByGroup(db_info::SQLiteInfo, group_id::Int)
#   
#     db = DB(db_info; busy_timeout=3000)
#     query = DBInterface.execute(db, "
#                                         SELECT
#                                             simulations.simulation_id,
#                                             simulations.group_id,
#                                             simulations.sim_params_id,
#                                             simulations.graph_adj_matrix,
#                                             simulations.use_seed,
#                                             simulations.rng_state,
#                                             simulations.periods_elapsed,
#                                             games.game,
#                                             games.payoff_matrix_size,
#                                             graphmodels.graph_params
#                                         FROM simulations
#                                         INNER JOIN games USING(game_id)
#                                         INNER JOIN graphmodels USING(graph_id)
#                                         INNER JOIN sim_params USING(sim_params_id)
#                                         WHERE simulations.group_id = $group_id
#                                 ")
#     df = DataFrame(query) #must create a DataFrame to acces query data
#     db_close(db)
#     return df
# end

#this function allows for RAM space savings during large iterative simulations
function querySimulationIDsByGroup(db_info::SQLiteInfo, group_id::Int)
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT
                                            simulation_id
                                        FROM simulations
                                        WHERE group_id = $group_id
                                        ORDER BY simulation_id ASC
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    db_close(db)
    return df
end

function execute_delete_simulation(db_info::SQLiteInfo, simulation_id::Int)
    db = DB(db_info; busy_timeout=3000)
    db_execute(db, "PRAGMA foreign_keys = ON;") #turn on foreign key support to allow cascading deletes
    status = db_execute(db, "DELETE FROM simulations WHERE simulation_id = $simulation_id;")
    db_close(db)
    return status
end


# Merge two SQLite files. These db files MUST have the same schema
function execute_merge_full(db_info_master::SQLiteInfo, db_info_merger::SQLiteInfo)
    db = DB(db_info_master)
    db = DB(db_info; busy_timeout=5000)
    db_execute(db, "ATTACH DATABASE '$(db_info_merger.filepath)' as merge_db;")
    db_execute(db, "INSERT OR IGNORE INTO games(game_name, game, payoff_matrix_size) SELECT game_name, game, payoff_matrix_size FROM merge_db.games;")
    db_execute(db, "INSERT OR IGNORE INTO graphmodels(graph, graph_type, graph_params, λ, β, α, blocks, p_in, p_out) SELECT graph, graph_type, graph_params, λ, β, α, blocks, p_in, p_out FROM merge_db.graphmodels;")
    db_execute(db, "INSERT OR IGNORE INTO sim_params(number_agents, memory_length, error, sim_params, use_seed) SELECT number_agents, memory_length, error, sim_params, use_seed FROM merge_db.sim_params;")
    db_execute(db, "INSERT OR IGNORE INTO starting_conditions(name, starting_condition) SELECT name, starting_condition FROM merge_db.starting_conditions;")
    db_execute(db, "INSERT OR IGNORE INTO stopping_conditions(name, stopping_condition) SELECT name, stopping_condition FROM merge_db.stopping_conditions;")
    db_execute(db, "INSERT OR IGNORE INTO sim_groups(description) SELECT description FROM merge_db.sim_groups;")
    db_execute(db, "INSERT INTO simulations(simulation_uuid, group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, periods_elapsed) SELECT simulation_uuid, group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, periods_elapsed FROM merge_db.simulations;")
    db_execute(db, "INSERT INTO agents(simulation_uuid, agent) SELECT simulation_uuid, agent from merge_db.agents;")
    db_execute(db, "DETACH DATABASE merge_db;")
    db_close(db)
    return nothing
end

# Merge temp distributed DBs into master DB.
function execute_merge_temp(db_info_master::SQLiteInfo, db_info_merger::SQLiteInfo)
    db = DB(db_info_master)
    db = DB(db_info; busy_timeout=rand(1:5000)) #this caused issues on cluster (.nfsXXXX files were being created. Does this stop the database connection from being closed?) NOTE: are all of these executes separate writes? can we put them all into one???
    db_execute(db, "ATTACH DATABASE '$(db_info_merger.filepath)' as merge_db;")
    db_execute(db, "INSERT OR IGNORE INTO simulations(simulation_uuid, group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, periods_elapsed) SELECT simulation_uuid, group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, periods_elapsed FROM merge_db.simulations;")
    db_execute(db, "INSERT OR IGNORE INTO agents(simulation_uuid, agent) SELECT simulation_uuid, agent from merge_db.agents;")
    db_execute(db, "DETACH DATABASE merge_db;")
    db_close(db)
    return nothing
end




function querySimulationsForBoxPlot(db_info::SQLiteInfo; game_id::Integer, number_agents::Integer, memory_length::Integer, error::Float64, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Int)
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end
    
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY graph_id
                                                    ORDER BY graph_id, simulation_id
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND sim_params.number_agents = $number_agents
                                            AND sim_params.memory_length = $memory_length
                                            AND sim_params.error = $error
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ") #dont need ROW_NUMBER() above, keeping for future use reference
    df = DataFrame(query)
    db_close(db)

    #error handling
    error_set = Set([])
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in df[:, :graph_id]]) : nothing

    for graph_id in graph_ids
        filtered_df = filter(:graph_id => id -> id == graph_id, df)
        if nrow(filtered_df) < sample_size
            push!(error_set, filtered_df[1, :graph])
        end
    end
    if !isempty(error_set)
        throw(ErrorException("Not enough samples for the following graphmodels: $error_set"))
    else
        return df
    end
end


function querySimulationsForMemoryLengthLinePlot(db_info::SQLiteInfo; game_id::Integer, number_agents::Integer, memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
    memory_lengths_sql = ""
    if memory_length_list !== nothing
        length(memory_length_list) == 1 ? memory_lengths_sql *= "AND sim_params.memory_length = $(memory_length_list[1])" : memory_lengths_sql *= "AND sim_params.memory_length IN $(Tuple(memory_length_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end


    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.memory_length, sim_params.error, simulations.graph_id
                                                    ORDER BY sim_params.memory_length
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND sim_params.number_agents = $number_agents
                                            $memory_lengths_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)


    #error handling
    function memoryLengthsDF() DataFrame(DBInterface.execute(db, "SELECT memory_length FROM sim_params")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM sim_params")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    memory_length_list === nothing ? memory_length_list = Set([memory_length for memory_length in memoryLengthsDF()[:, :memory_length]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for memory_length in memory_length_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:memory_length, :error, :graph_id] => (len, err, id) -> len == memory_length && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end




function querySimulationsForNumberAgentsLinePlot(db_info::SQLiteInfo; game_id::Integer, number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing, memory_length::Integer, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
    number_agents_sql = ""
    if number_agents_list !== nothing
        length(number_agents_list) == 1 ? number_agents_sql *= "AND sim_params.number_agents = $(number_agents_list[1])" : number_agents_sql *= "AND sim_params.number_agents IN $(Tuple(number_agents_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end


    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.number_agents, sim_params.error, simulations.graph_id
                                                    ORDER BY sim_params.number_agents
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND sim_params.memory_length = $memory_length
                                            $number_agents_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)


    #error handling
    function numberAgentsDF() DataFrame(DBInterface.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM sim_params")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for number_agents in number_agents_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:number_agents, :error, :graph_id] => (num, err, id) -> num == number_agents && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end


function query_simulations_for_transition_time_vs_memory_sweep(db_info::SQLiteInfo;
                                                                game_id::Integer,
                                                                memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                number_agents::Integer,
                                                                errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
                                                                graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                starting_condition_id::Integer,
                                                                stopping_condition_id::Integer,
                                                                sample_size::Integer
    )    
                                                                                
    memory_length_sql = ""
    if memory_length_list !== nothing
        length(memory_length_list) == 1 ? memory_length_sql *= "AND sim_params.memory_length = $(memory_length_list[1])" : memory_length_sql *= "AND sim_params.memory_length IN $(Tuple(memory_length_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end

    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.memory_length, sim_params.error, simulations.graph_id, simulations.starting_condition_id, simulations.stopping_condition_id
                                                    ORDER BY sim_params.memory_length
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND simulations.starting_condition_id = $starting_condition_id
                                            AND simulations.stopping_condition_id = $stopping_condition_id
                                            AND sim_params.number_agents = $number_agents
                                            $memory_length_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(DBInterface.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM sim_params")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for number_agents in number_agents_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:number_agents, :error, :graph_id] => (num, err, id) -> num == number_agents && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end



function query_simulations_for_transition_time_vs_population_sweep(db_info::SQLiteInfo;
                                                                    game_id::Integer,
                                                                    number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                    memory_length::Integer,
                                                                    errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
                                                                    graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                    starting_condition_id::Integer,
                                                                    stopping_condition_id::Integer,
                                                                    sample_size::Integer)    
                                                                                
    number_agents_sql = ""
    if number_agents_list !== nothing
        length(number_agents_list) == 1 ? number_agents_sql *= "AND sim_params.number_agents = $(number_agents_list[1])" : number_agents_sql *= "AND sim_params.number_agents IN $(Tuple(number_agents_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end

    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.number_agents, sim_params.error, simulations.graph_id, simulations.starting_condition_id, simulations.stopping_condition_id
                                                    ORDER BY sim_params.number_agents
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                graphmodels.λ,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND simulations.starting_condition_id = $starting_condition_id
                                            AND simulations.stopping_condition_id = $stopping_condition_id
                                            AND sim_params.memory_length = $memory_length
                                            $number_agents_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(DBInterface.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM sim_params")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for number_agents in number_agents_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:number_agents, :error, :graph_id] => (num, err, id) -> num == number_agents && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end


function query_simulations_for_transition_time_vs_population_stopping_condition(db_info::SQLiteInfo;
                                                                                game_id::Integer,
                                                                                number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                                memory_length::Integer,
                                                                                errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
                                                                                graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                                starting_condition_ids::Vector{<:Integer},
                                                                                stopping_condition_ids::Vector{<:Integer},
                                                                                sample_size::Integer)    
                                                                                
    number_agents_sql = ""
    if number_agents_list !== nothing
        length(number_agents_list) == 1 ? number_agents_sql *= "AND sim_params.number_agents = $(number_agents_list[1])" : number_agents_sql *= "AND sim_params.number_agents IN $(Tuple(number_agents_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end
    starting_condition_ids_sql = ""
    length(starting_condition_ids) == 1 ? starting_condition_ids_sql *= "AND simulations.starting_condition_id = $(starting_condition_ids[1])" : starting_condition_ids_sql *= "AND simulations.starting_condition_id IN $(Tuple(starting_condition_ids))"
    stopping_condition_ids_sql = ""
    length(stopping_condition_ids) == 1 ? stopping_condition_ids_sql *= "AND simulations.stopping_condition_id = $(stopping_condition_ids[1])" : stopping_condition_ids_sql *= "AND simulations.stopping_condition_id IN $(Tuple(stopping_condition_ids))"

    println(graph_ids_sql)
    println(starting_condition_ids_sql)

    println(stopping_condition_ids_sql)

    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.number_agents, sim_params.error, simulations.graph_id, simulations.starting_condition_id, simulations.stopping_condition_id
                                                    ORDER BY sim_params.number_agents
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND sim_params.memory_length = $memory_length
                                            $number_agents_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            $starting_condition_ids_sql
                                            $stopping_condition_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(DBInterface.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM sim_params")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for number_agents in number_agents_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:number_agents, :error, :graph_id] => (num, err, id) -> num == number_agents && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end



function query_simulations_for_transition_time_vs_memory_length_stopping_condition(db_info::SQLiteInfo;
                                                                                game_id::Integer,
                                                                                memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                                number_agents::Integer,
                                                                                errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
                                                                                graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
                                                                                starting_condition_ids::Vector{<:Integer},
                                                                                stopping_condition_ids::Vector{<:Integer},
                                                                                sample_size::Integer)    
                                                                                
    memory_lengths_sql = ""
    if memory_length_list !== nothing
        length(memory_length_list) == 1 ? memory_lengths_sql *= "AND sim_params.memory_length = $(memory_length_list[1])" : memory_lengths_sql *= "AND sim_params.memory_length IN $(Tuple(memory_length_list))"
    end
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end
    starting_condition_ids_sql = ""
    length(starting_condition_ids) == 1 ? starting_condition_ids_sql *= "AND simulations.starting_condition_id = $(starting_condition_ids[1])" : starting_condition_ids_sql *= "AND simulations.starting_condition_id IN $(Tuple(starting_condition_ids))"
    stopping_condition_ids_sql = ""
    length(stopping_condition_ids) == 1 ? stopping_condition_ids_sql *= "AND simulations.stopping_condition_id = $(stopping_condition_ids[1])" : stopping_condition_ids_sql *= "AND simulations.stopping_condition_id IN $(Tuple(stopping_condition_ids))"

    println(graph_ids_sql)
    println(starting_condition_ids_sql)

    println(stopping_condition_ids_sql)

    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY sim_params.memory_length, sim_params.error, simulations.graph_id, simulations.starting_condition_id, simulations.stopping_condition_id
                                                    ORDER BY sim_params.memory_length
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND sim_params.number_agents = $number_agents
                                            $memory_lengths_sql
                                            $errors_sql
                                            $graph_ids_sql
                                            $starting_condition_ids_sql
                                            $stopping_condition_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(DBInterface.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM sim_params")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for number_agents in number_agents_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:number_agents, :error, :graph_id] => (num, err, id) -> num == number_agents && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end



function querySimulationsForTimeSeries(db_info::SQLiteInfo;group_id::Integer)
    db = DB(db_info; busy_timeout=3000)

    #query the simulation info (only need one row since each entry in the timeseries group will have the same info)
    #separate this from agent query to save memory, as this query could be very memory intensive
    query_sim_info = DBInterface.execute(db, "
                                                SELECT
                                                    simulations.simulation_id,
                                                    sim_params.sim_params,
                                                    sim_params.number_agents,
                                                    sim_params.memory_length,
                                                    sim_params.error,
                                                    graphmodels.graph_id,
                                                    graphmodels.graph,
                                                    graphmodels.graph_params,
                                                    games.game_name,
                                                    games.game,
                                                    games.payoff_matrix_size
                                                FROM simulations
                                                INNER JOIN sim_params USING(sim_params_id)
                                                INNER JOIN games USING(game_id)
                                                INNER JOIN graphmodels USING(graph_id)
                                                WHERE simulations.group_id = $group_id
                                                LIMIT 1
                                        ")
    sim_info_df = DataFrame(query_sim_info)

    #query agents at each periods elapsed interval in the time series group
    query_agent_info = DBInterface.execute(db, "
                                                    SELECT
                                                        simulations.periods_elapsed,
                                                        agents.agent
                                                    FROM simulations
                                                    INNER JOIN agents USING(simulation_uuid)
                                                    WHERE simulations.group_id = $group_id
                                                    ORDER BY simulations.periods_elapsed ASC
                                                ")
    agent_df = DataFrame(query_agent_info)
    db_close(db)

    return (sim_info_df = sim_info_df, agent_df = agent_df)
end




function query_simulations_for_noise_structure_heatmap(db_info::SQLiteInfo;
                                                        game_id::Integer,
                                                        graph_params::Vector{<:Dict{Symbol, Any}},
                                                        errors::Vector{<:AbstractFloat},
                                                        mean_degrees::Vector{<:AbstractFloat},
                                                        number_agents::Integer,
                                                        memory_length::Integer,
                                                        starting_condition_id::Integer,
                                                        stopping_condition_id::Integer,
                                                        sample_size::Integer)
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
    mean_degrees_sql = ""
    if mean_degrees !== nothing
        length(mean_degrees) == 1 ? mean_degrees_sql *= "AND graphmodels.λ = $(mean_degrees[1])" : mean_degrees_sql *= "AND graphmodels.λ IN $(Tuple(mean_degrees))"
    end
    # graph_params_sql = "AND ("
    # if graph_params !== nothing
    #     for graph in graph_params
    #         graph_params_sql *= "("
    #         for (param, value) in graph
    #             graph_params_sql *= "graphmodels.$(string(param)) = $(value === nothing ? "null" : value) AND "
    #         end
    #         graph_params_sql = rstrip(graph_params_sql, collect(" AND "))
    #         graph_params_sql *= ") OR"
    #     end
    #     graph_params_sql = rstrip(graph_params_sql, collect(" OR"))
    #     graph_params_sql *= ")"
    # end
    graph_params_sql = "AND ("
    if graph_params !== nothing
        for graph in graph_params
            graph_params_sql *= "("
            for (param, value) in graph
                graph_params_sql *= "graphmodels.$(string(param)) = '$(value)' AND "
            end
            graph_params_sql = rstrip(graph_params_sql, collect(" AND "))
            graph_params_sql *= ") OR"
        end
        graph_params_sql = rstrip(graph_params_sql, collect(" OR"))
        graph_params_sql *= ")"
    end
    
    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY simulations.graph_id, sim_params.error, graphmodels.λ
                                                    ORDER BY sim_params.error, graphmodels.λ
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_type,
                                                graphmodels.graph_params,
                                                graphmodels.λ,
                                                graphmodels.β,
                                                graphmodels.α,
                                                graphmodels.p_in,
                                                graphmodels.p_out,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND simulations.starting_condition_id = $starting_condition_id
                                            AND simulations.stopping_condition_id = $stopping_condition_id
                                            AND sim_params.number_agents = $number_agents
                                            AND sim_params.memory_length = $memory_length
                                            $errors_sql
                                            $graph_params_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)
    println(df)
    return df

    # #error handling
    # errorsDF() = DataFrame(DBInterface.execute(db, "SELECT error FROM sim_params"))
    # graphmodelsDF() = DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels"))
    # meanDegreesDF() = DataFrame(DBInterface.execute(db, "SELECT λ FROM graphmodels"))

    # error_set = []
    # errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    # graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing
    # mean_degrees === nothing ? mean_degrees = Set([λ for λ in numberAgentsDF()[:, :λ]]) : nothing


    # db_close(db)

    # for mean_degree in mean_degrees
    #     for error in errors
    #         for graph_id in graph_ids
    #             filtered_df = filter([:λ, :error, :graph_id] => (λ, err, id) -> λ == mean_degree && err == error && id == graph_id, df)
    #             if nrow(filtered_df) < sample_size
    #                 push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id, λ: $mean_degree]\n")
    #             end
    #         end
    #     end
    # end
    # if !isempty(error_set)
    #     errors_formatted = ""
    #     for err in error_set
    #         errors_formatted *= err
    #     end
    #     throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    # else
    #     return df
    # end
end


function query_simulations_for_transition_time_vs_graph_params_sweep(db_info::SQLiteInfo;
                                                                game_id::Integer,
                                                                memory_length::Integer,
                                                                number_agents::Integer,
                                                                errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing,
                                                                graph_params::Vector{<:Dict{Symbol, Any}},
                                                                starting_condition_id::Integer,
                                                                stopping_condition_id::Integer,
                                                                sample_size::Integer
    )    
                                                                                
    errors_sql = ""
    if errors !== nothing
        length(errors) == 1 ? errors_sql *= "AND sim_params.error = $(errors[1])" : errors_sql *= "AND sim_params.error IN $(Tuple(errors))"
    end
 
    graph_params_sql = "AND ("
    for graph in graph_params
        graph_params_sql *= "("
        for (param, value) in graph
            graph_params_sql *= "graphmodels.$(string(param)) = '$(value)' AND "
        end
        graph_params_sql = rstrip(graph_params_sql, collect(" AND "))
        graph_params_sql *= ") OR"
    end
    graph_params_sql = rstrip(graph_params_sql, collect(" OR"))
    graph_params_sql *= ")"


    db = DB(db_info; busy_timeout=3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY simulations.graph_id, sim_params.error
                                                    ORDER BY sim_params.error
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.sim_params,
                                                sim_params.number_agents,
                                                sim_params.memory_length,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphmodels.graph_id,
                                                graphmodels.graph,
                                                graphmodels.graph_params,
                                                graphmodels.λ,
                                                graphmodels.β,
                                                graphmodels.α,
                                                graphmodels.p_in,
                                                graphmodels.p_out,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphmodels USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND simulations.starting_condition_id = $starting_condition_id
                                            AND simulations.stopping_condition_id = $stopping_condition_id
                                            AND sim_params.number_agents = $number_agents
                                            $errors_sql
                                            $graph_params_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ")
    df = DataFrame(query)

    return df
    #error handling
    function numberAgentsDF() DataFrame(DBInterface.execute(db, "SELECT number_agents FROM sim_params")) end
    function errorsDF() DataFrame(DBInterface.execute(db, "SELECT error FROM sim_params")) end
    function graphmodelsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphmodels")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphmodelsDF()[:, :graph_id]]) : nothing

    db_close(db)

    for number_agents in number_agents_list
        for error in errors
            for graph_id in graph_ids
                filtered_df = filter([:number_agents, :error, :graph_id] => (num, err, id) -> num == number_agents && err == error && id == graph_id, df)
                if nrow(filtered_df) < sample_size
                    push!(error_set, "Only $(nrow(filtered_df)) samples for [Number Agents: $number_agents, Memory Length: $memory_length, Error: $error, Graph: $graph_id]\n")
                end
            end
        end
    end
    if !isempty(error_set)
        errors_formatted = ""
        for err in error_set
            errors_formatted *= err
        end
        throw(ErrorException("Not enough samples for the following simulations:\n$errors_formatted"))
    else
        return df
    end
end