function initDataBase(db_filepath::String)
    #create or connect to database
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    #create 'games' table (currently only the "bargaining game" exists)
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS games
                            (
                                game_id INTEGER PRIMARY KEY,
                                game_name TEXT NOT NULL,
                                game TEXT NOT NULL,
                                payoff_matrix_size TEXT NOT NULL,
                                UNIQUE(game_name, game)
                            );
                    ")

    #create 'graphs' table which stores the graph types with their specific parameters (parameters might go in different table?)
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS graphs
                            (
                                graph_id INTEGER PRIMARY KEY,
                                graph_type TEXT NOT NULL,
                                graph_params TEXT NOT NULL,
                                λ REAL DEFAULT NULL,
                                κ REAL DEFAULT NULL,
                                β REAL DEFAULT NULL,
                                α REAL DEFAULT NULL,
                                communities INTEGER DEFAULT NULL,
                                internal_λ REAL DEFAULT NULL,
                                external_λ REAL DEFAULT NULL,
                                UNIQUE(graph_type, graph_params)
                            );
                    ")

    #create 'sim_params' table which contains information specific to each simulation
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS sim_params
                            (
                                sim_params_id INTEGER PRIMARY KEY,
                                number_agents INTEGER NOT NULL,
                                memory_length INTEGER NOT NULL,
                                error REAL NOT NULL,
                                sim_params TEXT NOT NULL,
                                use_seed BOOLEAN NOT NULL,
                                UNIQUE(sim_params, use_seed),
                                CHECK (use_seed in (0, 1))
                            );
                    ")

    #create 'sim_groups' table to group simulations and give the groups an easy-access description (version control is handled with the prev_simulation_id column in the individual simulation saves)
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS sim_groups
                            (
                                sim_group_id INTEGER PRIMARY KEY,
                                description TEXT DEFAULT NULL,
                                UNIQUE(description)
                            );
                    ")

    #create 'simulations' table which contains information specific to each simulation
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS simulations
                            (
                                simulation_id INTEGER PRIMARY KEY,
                                simulation_uuid TEXT NOT NULL,
                                sim_group_id INTEGER DEFAULT NULL,
                                prev_simulation_uuid TEXT DEFAULT NULL,
                                game_id INTEGER NOT NULL,
                                graph_id INTEGER NOT NULL,
                                sim_params_id INTEGER NOT NULL,
                                graph_adj_matrix TEXT DEFAULT NULL,
                                rng_state TEXT NOT NULL,
                                periods_elapsed INTEGER NOT NULL,
                                FOREIGN KEY (sim_group_id)
                                    REFERENCES sim_groups (sim_group_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (prev_simulation_uuid)
                                    REFERENCES simulations (simulation_uuid),
                                FOREIGN KEY (game_id)
                                    REFERENCES games (game_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (graph_id)
                                    REFERENCES graphs (graph_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (sim_params_id)
                                    REFERENCES sim_params (sim_params_id)
                                    ON DELETE CASCADE,
                                UNIQUE(simulation_uuid)
                            );
                    ")

    #create 'agents' table which contains json strings of agent types (with memory states). FK points to specific simulation
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS agents
                            (
                                agent_id INTEGER PRIMARY KEY,
                                simulation_uuid TEXT NOT NULL,
                                agent TEXT NOT NULL,
                                FOREIGN KEY (simulation_uuid)
                                    REFERENCES simulations (simulation_uuid)
                                    ON DELETE CASCADE
                            );
                    ")
    SQLite.close(db)
end

#this DB only needs tables for simulations and agents. These will be collected into the master DB later
function initTempSimulationDB(db_filepath::String)
    #create or connect to database
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)

    #create 'simulations' table which contains information specific to each simulation
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS simulations
                            (
                                simulation_id INTEGER PRIMARY KEY,
                                simulation_uuid TEXT NOT NULL,
                                sim_group_id INTEGER DEFAULT NULL,
                                prev_simulation_uuid TEXT DEFAULT NULL,
                                game_id INTEGER NOT NULL,
                                graph_id INTEGER NOT NULL,
                                sim_params_id INTEGER NOT NULL,
                                graph_adj_matrix TEXT DEFAULT NULL,
                                rng_state TEXT NOT NULL,
                                periods_elapsed INTEGER NOT NULL,
                                FOREIGN KEY (sim_group_id)
                                    REFERENCES sim_groups (sim_group_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (prev_simulation_uuid)
                                    REFERENCES simulations (simulation_uuid),
                                FOREIGN KEY (game_id)
                                    REFERENCES games (game_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (graph_id)
                                    REFERENCES graphs (graph_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (sim_params_id)
                                    REFERENCES sim_params (sim_params_id)
                                    ON DELETE CASCADE,
                                UNIQUE(simulation_uuid)
                            );
                    ")

    #create 'agents' table which contains json strings of agent types (with memory states). FK points to specific simulation
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS agents
                            (
                                agent_id INTEGER PRIMARY KEY,
                                simulation_uuid TEXT NOT NULL,
                                agent TEXT NOT NULL,
                                FOREIGN KEY (simulation_uuid)
                                    REFERENCES simulations (simulation_uuid)
                                    ON DELETE CASCADE
                            );
                    ")
    SQLite.close(db)
end



function insertGame(db_filepath::String, game_name::String, game::String, payoff_matrix_size::String)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    status = SQLite.execute(db, "
                                    INSERT OR IGNORE INTO games
                                    (
                                        game_name,
                                        game,
                                        payoff_matrix_size
                                    )
                                    VALUES
                                    (
                                        '$game_name',
                                        '$game',
                                        '$payoff_matrix_size'
                                    );
                            ")
    query = DBInterface.execute(db, "
                                        SELECT game_id
                                        FROM games
                                        WHERE game_name = '$game_name'
                                        AND game = '$game';
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    insert_row = df[1, :game_id]
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: games]... INSERT STATUS: [$status] GAME_ID: [$insert_row]]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertGraph(db_filepath::String, graph_type::String, graph_params_str::String, db_graph_params_dict::Dict{Symbol, Any})
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    insert_string_columns = "graph_type, graph_params, "
    insert_string_values = "'$graph_type', '$graph_params_str', "
    for (param, value) in db_graph_params_dict
        if value !== nothing
            insert_string_columns *= "'$param', "
            insert_string_values *= "$value, "
        end
    end
    insert_string_columns = rstrip(insert_string_columns, [' ', ',']) #strip off the comma and space at the end of the string
    insert_string_values = rstrip(insert_string_values, [' ', ','])

    status = SQLite.execute(db, "
                                    INSERT OR IGNORE INTO graphs
                                    (
                                        $insert_string_columns
                                    )
                                    VALUES
                                    (
                                        $insert_string_values
                                    );
                            ")
    query = DBInterface.execute(db, "
                                        SELECT graph_id
                                        FROM graphs
                                        WHERE graph_type = '$graph_type'
                                        AND graph_params = '$graph_params_str';
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    insert_row = df[1, :graph_id]
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: graphs]... INSERT STATUS: [$status] GRAPH_ID: [$insert_row]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertSimParams(db_filepath::String, sim_params::SimParams, sim_params_str::String, use_seed::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    status = SQLite.execute(db, "
                                    INSERT OR IGNORE INTO sim_params
                                    (
                                        number_agents,
                                        memory_length,
                                        error,
                                        sim_params,
                                        use_seed
                                    )
                                    VALUES
                                    (
                                        $(sim_params.number_agents),
                                        $(sim_params.memory_length),
                                        $(sim_params.error),
                                        '$sim_params_str',
                                        $use_seed
                                );
                            ")
    query = DBInterface.execute(db, "
                                        SELECT sim_params_id
                                        FROM sim_params
                                        WHERE sim_params = '$sim_params_str'
                                        AND use_seed = $use_seed;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    insert_row = df[1, :sim_params_id]
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: sim_params]... INSERT STATUS: [$status] SIM_PARAMS_ID: [$insert_row]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertSimGroup(db_filepath::String, description::String)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    status = SQLite.execute(db, "
                                    INSERT INTO sim_groups
                                    (
                                        description
                                    )
                                    VALUES
                                    (
                                        '$description'
                                );
                            ")
    insert_row = SQLite.last_insert_rowid(db)
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: sim_groups]... INSERT STATUS: [$status] SIM_GROUP_ID: [$insert_row]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertSimulation(db, sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, game_id::Integer, graph_id::Integer, sim_params_id::Integer, graph_adj_matrix_str::String, rng_state::String, periods_elapsed::Integer)
    uuid = "$(uuid4())"
    
    sim_group_id === nothing ? sim_group_id = "NULL" : nothing
    prev_simulation_uuid === nothing ?  prev_simulation_uuid = "NULL" : nothing

    # db = SQLite.DB("$db_filepath")
    # SQLite.busy_timeout(db, 3000)
    status = SQLite.execute(db, "
                                    INSERT INTO simulations
                                    (
                                        simulation_uuid,
                                        sim_group_id,
                                        prev_simulation_uuid,
                                        game_id,
                                        graph_id,
                                        sim_params_id,
                                        graph_adj_matrix,
                                        rng_state,
                                        periods_elapsed
                                    )
                                    VALUES
                                    (
                                        '$uuid',
                                        $sim_group_id,
                                        '$prev_simulation_uuid',
                                        $game_id,
                                        $graph_id,
                                        $sim_params_id,
                                        '$graph_adj_matrix_str',
                                        '$rng_state',
                                        $periods_elapsed
                                );
                            ")
    insert_row = SQLite.last_insert_rowid(db)
    # SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: simulations]... INSERT STATUS: [$status] SIMULATION_ID: [$insert_row]", insert_row_id = insert_row, uuid = uuid)
    return tuple_to_return
end

function insertAgents(db, simulation_uuid::String, agent_list::Vector{String})
    # db = SQLite.DB("$db_filepath")
    # SQLite.busy_timeout(db, 3000)
    values_string = "" #construct a values string to insert multiple agents into db table
    for agent in agent_list
        values_string *= "('$simulation_uuid', '$agent'), "
    end
    values_string = rstrip(values_string, [' ', ','])
    #println(values_string)
     
    status = SQLite.execute(db, "
                                    INSERT INTO agents
                                    (
                                        simulation_uuid,
                                        agent
                                    )
                                    VALUES
                                        $values_string;
                            ")
    # SQLite.close(db)
    return (status_message = "SQLite [SimulationSaves: agents]... INSERT STATUS: [$status]")
end


function insertSimulationWithAgents(db_filepath::String, sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, game_id::Integer, graph_id::Integer, sim_params_id::Integer, graph_adj_matrix_str::String, rng_state::String, periods_elapsed::Integer, agent_list::Vector{String})
    simulation_uuid = "$(uuid4())"
    
    #prepare simulation SQL
    sim_group_id === nothing ? sim_group_id = "NULL" : nothing
    prev_simulation_uuid === nothing ?  prev_simulation_uuid = "NULL" : nothing

    #prepare agents SQL
    agent_values_string = "" #construct a values string to insert multiple agents into db table
    for agent in agent_list
        agent_values_string *= "('$simulation_uuid', '$agent'), "
    end
    agent_values_string = rstrip(agent_values_string, [' ', ','])

    #open DB connection
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)

    #first insert simulation with simulation_uuid
    simulation_status = SQLite.execute(db, "
                                    INSERT INTO simulations
                                    (
                                        simulation_uuid,
                                        sim_group_id,
                                        prev_simulation_uuid,
                                        game_id,
                                        graph_id,
                                        sim_params_id,
                                        graph_adj_matrix,
                                        rng_state,
                                        periods_elapsed
                                    )
                                    VALUES
                                    (
                                        '$simulation_uuid',
                                        $sim_group_id,
                                        '$prev_simulation_uuid',
                                        $game_id,
                                        $graph_id,
                                        $sim_params_id,
                                        '$graph_adj_matrix_str',
                                        '$rng_state',
                                        $periods_elapsed
                                );
                            ")

    #then insert agents with FK of simulation_uuid 
    agents_status = SQLite.execute(db, "
                                    INSERT INTO agents
                                    (
                                        simulation_uuid,
                                        agent
                                    )
                                    VALUES
                                        $agent_values_string;
                            ")
    SQLite.close(db)

    tuple_to_return = (status_message = "SQLite [SimulationSaves: simulations & agents]... SIMULATION INSERT STATUS: [$simulation_status] AGENTS INSERT STATUS: [$agents_status] SIMULATION_UUID: [$simulation_uuid]", simulation_uuid = simulation_uuid)
    return tuple_to_return
end


function queryGame(db_filepath::String, game_id::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM games
                                        WHERE game_id = $game_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

function queryGraph(db_filepath::String, graph_id::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM graphs
                                        WHERE graph_id = $graph_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

function querySimParams(db_filepath::String, sim_params_id::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM sim_params
                                        WHERE sim_params_id = $sim_params_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

function querySimGroups(db_filepath::String, sim_group_id::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM sim_groups
                                        WHERE sim_group_id = $sim_group_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

function querySimulation(db_filepath::String, simulation_id::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM simulations
                                        WHERE simulation_id = $simulation_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

function queryAgents(db_filepath::String, simulation_id::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM agents
                                        WHERE simulation_id = $simulation_id
                                        ORDER BY agent_id ASC;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

function querySimulationForRestore(db_filepath::String, simulation_id::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT
                                            simulations.simulation_id,
                                            simulations.sim_group_id,
                                            sim_params.sim_params,
                                            sim_params.use_seed,
                                            simulations.rng_state,
                                            simulations.periods_elapsed,
                                            simulations.graph_adj_matrix,
                                            graphs.graph_params,
                                            games.game,
                                            games.payoff_matrix_size
                                        FROM simulations
                                        INNER JOIN games USING(game_id)
                                        INNER JOIN graphs USING(graph_id)
                                        INNER JOIN sim_params USING(sim_params_id)
                                        WHERE simulations.simulation_id = $simulation_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

function queryAgentsForRestore(db_filepath::String, simulation_id::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT agent
                                        FROM agents
                                        WHERE simulation_id = $simulation_id
                                        ORDER BY agent_id ASC;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end



function querySimulationsByGroup(db_filepath::String, sim_group_id::Int)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT
                                            simulations.simulation_id,
                                            simulations.sim_group_id,
                                            simulations.sim_params,
                                            simulations.graph_adj_matrix,
                                            simulations.use_seed,
                                            simulations.rng_state,
                                            simulations.periods_elapsed,
                                            games.game,
                                            games.payoff_matrix_size,
                                            graphs.graph_params,
                                        FROM simulations
                                        INNER JOIN games USING(game_id)
                                        INNER JOIN graphs USING(graph_id)
                                        INNER JOIN sim_params USING(sim_params_id)
                                        WHERE simulations.sim_group_id = $sim_group_id
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

#this function allows for RAM space savings during large iterative simulations
function querySimulationIDsByGroup(db_filepath::String, sim_group_id::Int)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT
                                            simulation_id
                                        FROM simulations
                                        WHERE sim_group_id = $sim_group_id
                                        ORDER BY simulation_id ASC
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

function deleteSimulationById(db_filepath::String, simulation_id::Int)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    SQLite.execute(db, "PRAGMA foreign_keys = ON;") #turn on foreign key support to allow cascading deletes
    status = SQLite.execute(db, "DELETE FROM simulations WHERE simulation_id = $simulation_id;")
    SQLite.close(db)
    return status
end


# Merge two SQLite files. These db files MUST have the same schema
function mergeDatabases(db_filepath_master::String, db_filepath_merger::String)
    db = SQLite.DB("$db_filepath_master")
    SQLite.busy_timeout(db, 5000)
    SQLite.execute(db, "ATTACH DATABASE '$db_filepath_merger' as merge_db;")
    SQLite.execute(db, "INSERT OR IGNORE INTO games(game_name, game, payoff_matrix_size) SELECT game_name, game, payoff_matrix_size FROM merge_db.games;")
    SQLite.execute(db, "INSERT OR IGNORE INTO graphs(graph_type, graph_params, λ, κ, β, α, communities, internal_λ, external_λ) SELECT graph_type, graph_params, λ, κ, β, α, communities, internal_λ, external_λ FROM merge_db.graphs;")
    SQLite.execute(db, "INSERT OR IGNORE INTO sim_params(number_agents, memory_length, error, sim_params, use_seed) SELECT number_agents, memory_length, error, sim_params, use_seed FROM merge_db.sim_params;")
    SQLite.execute(db, "INSERT OR IGNORE INTO sim_groups(description) SELECT description FROM merge_db.sim_groups;")
    SQLite.execute(db, "INSERT INTO simulations(simulation_uuid, sim_group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, graph_adj_matrix, rng_state, periods_elapsed) SELECT simulation_uuid, sim_group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, graph_adj_matrix, rng_state, periods_elapsed FROM merge_db.simulations;")
    SQLite.execute(db, "INSERT INTO agents(simulation_uuid, agent) SELECT simulation_uuid, agent from merge_db.agents;")
    SQLite.execute(db, "DETACH DATABASE merge_db;")
    SQLite.close(db)
    return nothing
end

# Merge temp distributed DBs into master DB.
function mergeTempDatabases(db_filepath_master::String, db_filepath_merger::String)
    db = SQLite.DB("$db_filepath_master")
    SQLite.busy_timeout(db, 5000)
    SQLite.execute(db, "ATTACH DATABASE '$db_filepath_merger' as merge_db;")
    SQLite.execute(db, "INSERT INTO simulations(simulation_uuid, sim_group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, graph_adj_matrix, rng_state, periods_elapsed) SELECT simulation_uuid, sim_group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, graph_adj_matrix, rng_state, periods_elapsed FROM merge_db.simulations;")
    SQLite.execute(db, "INSERT INTO agents(simulation_uuid, agent) SELECT simulation_uuid, agent from merge_db.agents;")
    SQLite.execute(db, "DETACH DATABASE merge_db;")
    SQLite.close(db)
    return nothing
end




function querySimulationsForBoxPlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length::Integer, error::Float64, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Int)
    graph_ids_sql = ""
    if graph_ids !== nothing
        graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
    end
    
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
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
                                                graphs.graph_id,
                                                graphs.graph_type,
                                                graphs.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
                                            WHERE simulations.game_id = $game_id
                                            AND sim_params.number_agents = $number_agents
                                            AND sim_params.memory_length = $memory_length
                                            AND sim_params.error = $error
                                            $graph_ids_sql
                                            )
                                        WHERE RowNum <= $sample_size;
                                ") #dont need ROW_NUMBER() above, keeping for future use reference
    df = DataFrame(query)
    SQLite.close(db)

    #error handling
    graph_types_error_set = Set([])
    for graph_id in graph_ids
        filtered_df = filter(:graph_id => id -> id == graph_id, df)
        if nrow(filtered_df) < sample_size
            push!(graph_types_error_set, filtered_df[1, :graph_type])
        end
    end
    if !isempty(graph_types_error_set)
        throw(ErrorException("Not enough samples for graphs: $graph_types_error_set"))
    else
        return df
    end
end