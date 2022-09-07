using SQLite, TypedTables, DataFrames #might be able to get rid of TypedTables (not sure if DataFrames are better or worse)

function initSQL()
    #create or connect to database
    db = SQLite.DB("SimulationSaves.sqlite")

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
                                graph_params_dict TEXT NOT NULL,
                                λ REAL DEFAULT NULL,
                                k REAL DEFAULT NULL,
                                β REAL DEFAULT NULL,
                                α REAL DEFAULT NULL,
                                communities INTEGER DEFAULT NULL,
                                internal_λ REAL DEFAULT NULL,
                                external_λ REAL DEFAULT NULL,
                                UNIQUE(graph_type, graph_params_dict)
                            );
                    ")

    #create simulations table which contains information specific to each simulation
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS simulations
                            (
                                simulation_id INTEGER PRIMARY KEY,
                                number_agents INTEGER NOT NULL,
                                memory_length INTEGER NOT NULL,
                                error REAL NOT NULL,
                                sim_params TEXT NOT NULL,
                                game_id INTEGER NOT NULL,
                                graph_id INTEGER NOT NULL,
                                graph_adj_matrix TEXT NOT NULL,
                                use_seed BOOLEAN NOT NULL,
                                rng_state TEXT NOT NULL,
                                periods_elapsed INTEGER NOT NULL,
                                FOREIGN KEY (game_id)
                                    REFERENCES games (game_id),
                                FOREIGN KEY (graph_id)
                                    REFERENCES graphs (graph_id),
                                CHECK (use_seed in (0, 1))
                            );
                    ")
                        #UNIQUE (number_agents, memory_length, error, sim_params, game_id, graph_id, graph_adj_matrix, use_seed, rng_state, periods_elapsed) might need to implement this

    #create agents table which contains json strings of agent types (with memory states). FK points to specific simulation
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS agents
                            (
                                agent_id INTEGER PRIMARY KEY,
                                simulation_id INTEGER NOT NULL,
                                agent TEXT NOT NULL,
                                FOREIGN KEY (simulation_id)
                                    REFERENCES simulations (simulation_id)
                            );
                    ")
    SQLite.close(db)
end

function insertGameSQL(game_name::String, game::String, payoff_matrix_size::String)
    db = SQLite.DB("SimulationSaves.sqlite")
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
    df = DataFrame(query) #must create a DataFrame to access query values
    insert_row = df[1, :game_id]
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: games]... INSERT STATUS: [$status] GAME_ID: [$insert_row]]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertGraphSQL(graph_type::String, graph_params_dict_str::String, db_params_dict::Dict{Symbol, Any})
    db = SQLite.DB("SimulationSaves.sqlite")

    insert_string_columns = "graph_type, graph_params_dict, "
    insert_string_values = "'$graph_type', '$graph_params_dict_str', "
    for (param, value) in db_params_dict
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
                                        AND graph_params_dict = '$graph_params_dict_str';
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    insert_row = df[1, :graph_id]
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: graphs]... INSERT STATUS: [$status] GRAPH_ID: [$insert_row]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertSimulationSQL(params::SimParams, sim_params_str::String, graph_adj_matrix_str::String, periods_elapsed::Integer, game_id::Integer, graph_id::Integer, seed_bool::Integer, rng_state::String)
    db = SQLite.DB("SimulationSaves.sqlite")
    
    status = SQLite.execute(db, "
                                    INSERT INTO simulations
                                    (
                                        number_agents,
                                        memory_length,
                                        error,
                                        sim_params,
                                        game_id,
                                        graph_id,
                                        graph_adj_matrix,
                                        periods_elapsed,
                                        use_seed,
                                        rng_state
                                    )
                                    VALUES
                                    (
                                        $(params.number_agents),
                                        $(params.memory_length),
                                        $(params.error),
                                        '$sim_params_str',
                                        $game_id,
                                        $graph_id,
                                        '$graph_adj_matrix_str',
                                        $periods_elapsed,
                                        $seed_bool,
                                        '$rng_state'
                                );
                            ")
    insert_row = SQLite.last_insert_rowid(db)
    println(insert_row)
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: simulations]... INSERT STATUS: [$status] SIMULATION_ID: [$insert_row]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertAgentsSQL(agent_list::Vector{String}, simulation_id::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")

    values_string = "" #construct a values string to insert multiple agents into db table
    for agent in agent_list
        values_string *= "($simulation_id, '$agent'), "
    end
    values_string = rstrip(values_string, [' ', ','])
    #println(values_string)
     
    status = SQLite.execute(db, "
                                    INSERT INTO agents
                                    (
                                        simulation_id,
                                        agent
                                    )
                                    VALUES
                                        $values_string;
                            ")
    SQLite.close(db)
    return "SQLite [SimulationSaves: agents]... INSERT STATUS: [$status]"
end

function queryGameSQL(game_id::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")

    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM games
                                        WHERE game_id = $game_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end

function queryGraphSQL(graph_id::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")

    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM graphs
                                        WHERE graph_id = $graph_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end

function querySimulationSQL(simulation_id::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")

    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM simulations
                                        WHERE simulation_id = $simulation_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end

function queryAgentsSQL(simulation_id::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")

    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM agents
                                        WHERE simulation_id = $simulation_id
                                        ORDER BY agent_id ASC;
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end

function queryFullSimulation(simulation_id::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")

    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM simulations
                                        INNER JOIN agents USING(simulation_id)
                                        INNER JOIN games USING(game_id)
                                        INNER JOIN graphs USING(graph_id)
                                        WHERE simulation_id = $simulation_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end

function queryForSimReproduction(game_name::String, graph_params::Dict{Symbol, Any}, number_agents::Integer, memory_length::Integer, error::Float64)
    db = SQLite.DB("SimulationSaves.sqlite")

    where_params_string = ""
    for (param, value) in graph_params
        where_params_string *= "graphs.$param = $value AND "
    end
    where_params_string = rstrip(where_params_string, [' ', 'A', 'N', 'D'])

    query = DBInterface.execute(db, "
                                        SELECT
                                            simulations.sim_params,
                                            simulations.graph_adj_matrix,
                                            simulations.use_seed,
                                            simulations.rng_state,
                                            games.game,
                                            games.payoff_matrix_size,
                                            graphs.graph_params_dict
                                        FROM simulations
                                        INNER JOIN games USING(game_id)
                                        INNER JOIN graphs USING(graph_id)
                                        WHERE games.game_name = '$game_name'
                                        AND $where_params_string
                                        AND simulations.number_agents = $number_agents
                                        AND simulations.memory_length = $memory_length
                                        AND simulations.error = $error;
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end