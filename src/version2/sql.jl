using SQLite, DataFrames

function initDataBase()
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

    #create simulations table which contains information specific to each simulation
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS sim_params
                            (
                                sim_params_id INTEGER PRIMARY KEY,
                                grouping_id INTEGER,
                                number_agents INTEGER NOT NULL,
                                memory_length INTEGER NOT NULL,
                                error REAL NOT NULL,
                                sim_params TEXT NOT NULL,
                                use_seed BOOLEAN NOT NULL,
                                UNIQUE(grouping_id, sim_params, use_seed),
                                CHECK (use_seed in (0, 1))
                            );
                    ")

    #create simulations table which contains information specific to each simulation
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS simulations
                            (
                                simulation_id INTEGER PRIMARY KEY,
                                prev_simulation_id INTEGER DEFAULT NULL,
                                game_id INTEGER NOT NULL,
                                graph_id INTEGER NOT NULL,
                                sim_params_id INTEGER NOT NULL,
                                graph_adj_matrix TEXT DEFAULT NULL,
                                rng_state TEXT NOT NULL,
                                periods_elapsed INTEGER NOT NULL,
                                FOREIGN KEY (prev_simulation_id)
                                    REFERENCES simulations (prev_simulation_id),
                                FOREIGN KEY (game_id)
                                    REFERENCES games (game_id),
                                FOREIGN KEY (graph_id)
                                    REFERENCES graphs (graph_id),
                                FOREIGN KEY (sim_params_id)
                                    REFERENCES sim_params (sim_params_id)
                            );
                    ")

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

function insertGame(game_name::String, game::String, payoff_matrix_size::String)
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

function insertGraph(graph_type::String, graph_params_str::String, db_graph_params_dict::Dict{Symbol, Any})
    db = SQLite.DB("SimulationSaves.sqlite")

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
    df = DataFrame(query) #must create a DataFrame to access query values
    insert_row = df[1, :graph_id]
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: graphs]... INSERT STATUS: [$status] GRAPH_ID: [$insert_row]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertSimParams(grouping_id::Int, sim_params::SimParams, sim_params_str::String, use_seed::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")
    status = SQLite.execute(db, "
                                    INSERT OR IGNORE INTO sim_params
                                    (
                                        grouping_id,
                                        number_agents,
                                        memory_length,
                                        error,
                                        sim_params,
                                        use_seed
                                    )
                                    VALUES
                                    (
                                        $grouping_id,
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
                                        WHERE grouping_id = $grouping_id
                                        AND sim_params = '$sim_params_str'
                                        AND use_seed = $use_seed;
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    insert_row = df[1, :sim_params_id]
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: sim_params]... INSERT STATUS: [$status] SIM_PARAMS_ID: [$insert_row]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertSimulation(prev_simulation_id::Integer, game_id::Integer, graph_id::Integer, sim_params_id::Integer, graph_adj_matrix_str::String, rng_state::String, periods_elapsed::Integer)
    if prev_simulation_id == 0
        prev_simulation_id = "NULL"
    end
    db = SQLite.DB("SimulationSaves.sqlite")
    status = SQLite.execute(db, "
                                    INSERT INTO simulations
                                    (
                                        prev_simulation_id,
                                        game_id,
                                        graph_id,
                                        sim_params_id,
                                        graph_adj_matrix,
                                        rng_state,
                                        periods_elapsed
                                    )
                                    VALUES
                                    (
                                        $prev_simulation_id,
                                        $game_id,
                                        $graph_id,
                                        $sim_params_id,
                                        '$graph_adj_matrix_str',
                                        '$rng_state',
                                        $periods_elapsed
                                );
                            ")
    insert_row = SQLite.last_insert_rowid(db)
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: simulations]... INSERT STATUS: [$status] SIMULATION_ID: [$insert_row]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertAgents(simulation_id::Integer, agent_list::Vector{String})
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
    return (status_message = "SQLite [SimulationSaves: agents]... INSERT STATUS: [$status]")
end

function queryGame(game_id::Integer)
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

function queryGraph(graph_id::Integer)
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

function querySimParams(sim_params_id::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM sim_params
                                        WHERE sim_params_id = $sim_params_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end

function querySimulation(simulation_id::Integer)
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

function queryAgents(simulation_id::Integer)
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

function querySimulationForRestore(simulation_id::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")
    query = DBInterface.execute(db, "
                                        SELECT
                                            simulations.simulation_id,
                                            sim_params.grouping_id,
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
                                        WHERE simulation_id = $simulation_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end

function queryAgentsForRestore(simulation_id::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")
    query = DBInterface.execute(db, "
                                        SELECT agent
                                        FROM agents
                                        WHERE simulation_id = $simulation_id
                                        ORDER BY agent_id ASC;
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end



function querySimulationsByGroup(grouping_id::Int)
    db = SQLite.DB("SimulationSaves.sqlite")
    query = DBInterface.execute(db, "
                                        SELECT
                                            simulations.simulation_id,
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
                                        WHERE simulations.grouping_id = $grouping_id
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end

#this function allows for RAM space savings during large iterative simulations
function querySimulationIDsByGroup(grouping_id::Int)
    db = SQLite.DB("SimulationSaves.sqlite")
    query = DBInterface.execute(db, "
                                        SELECT
                                            simulation_id
                                        FROM simulations
                                        WHERE grouping_id = $grouping_id
                                        ORDER BY simulation_id ASC
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end


function querySimulationsForPotting(grouping_id::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")
    query = DBInterface.execute(db, "
                                        SELECT
                                            simulations.simulation_id,
                                            simulations.sim_params,
                                            simulations.periods_elapsed,
                                            graphs.graph_params,
                                            games.game_name,
                                        FROM simulations
                                        INNER JOIN games USING(game_id)
                                        INNER JOIN graphs USING(graph_id)
                                        WHERE grouping_id = $grouping_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to access query values
    SQLite.close(db)
    return df
end