using SQLite, TypedTables

function initSQL()
    #create or connect to database
    db = SQLite.DB("SimulationSaves.sqlite")

    #create 'games' table (currently only the "bargaining game" exists)
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS games
                            (
                                'game_id' INTEGER PRIMARY KEY,
                                'name' TEXT NOT NULL,
                                'payoff_matrix' TEXT,
                                UNIQUE('name', 'payoff_matrix')
                            );
                    ")

    #create 'graphs' table which stores the graph types with their specific parameters (parameters might go in different table?)
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS graphs
                            (
                                'graph_id' INTEGER PRIMARY KEY,
                                'type' TEXT NOT NULL,
                                'graph_params_dict' TEXT NOT NULL,
                                'λ' REAL DEFAULT NULL,
                                'k' REAL DEFAULT NULL,
                                'β' REAL DEFAULT NULL,
                                'α' REAL DEFAULT NULL,
                                'communities' INTEGER DEFAULT NULL,
                                'internal_λ' REAL DEFAULT NULL,
                                'external_λ' REAL DEFAULT NULL,
                                UNIQUE('type', 'graph_params_dict')
                            );
                    ")

    #create simulations table which contains information specific to each simulation
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS simulations
                            (
                                'simulation_id' INTEGER PRIMARY KEY,
                                'sim_params' TEXT NOT NULL,
                                'game_id' INTEGER NOT NULL,
                                'graph_id' INTEGER NOT NULL,
                                'graph_adj_matrix' TEXT NOT NULL,
                                'periods_elapsed' INTEGER NOT NULL,
                                FOREIGN KEY (game_id)
                                    REFERENCES games (game_id),
                                FOREIGN KEY (graph_id)
                                    REFERENCES graphs (graph_id)
                            );
                    ")
                        #'description' TEXT NOT NULL UNIQUE, for description if needed later (2nd column)

    #create agents table which contains json strings of agent types (with memory states). FK points to specific simulation
    SQLite.execute(db, "
                            CREATE TABLE IF NOT EXISTS agents
                            (
                                'agent_id' INTEGER PRIMARY KEY,
                                'simulation_id' INTEGER NOT NULL,
                                'agent' TEXT NOT NULL,
                                FOREIGN KEY (simulation_id)
                                    REFERENCES simulations (simulation_id)
                            );
                    ")
    SQLite.close(db)
end

function insertGameSQL(name::String, payoff_matrix_str::String)
    db = SQLite.DB("SimulationSaves.sqlite")
    status = SQLite.execute(db, "
                                    INSERT OR IGNORE INTO games
                                    (
                                        'name',
                                        'payoff_matrix'
                                    )
                                    VALUES
                                    (
                                        '$name',
                                        '$payoff_matrix_str'
                                    );
                            ")
    query = DBInterface.execute(db, "
                                        SELECT game_id
                                        FROM games
                                        WHERE name = '$name'
                                        AND payoff_matrix = '$payoff_matrix_str';
                                ")
    table = Table(query) #must create a TypedTable to access query values
    insert_row = table[1].game_id
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: games]... INSERT STATUS: [$status] GAME_ID: [$insert_row]]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertGraphSQL(type::String, graph_params_dict_str::String, db_params_dict::Dict{Symbol, Any})
    db = SQLite.DB("SimulationSaves.sqlite")

    insert_string_columns = "'type', 'graph_params_dict', "
    insert_string_values = "'$type', '$graph_params_dict_str', "
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
                                        WHERE type = '$type'
                                        AND graph_params_dict = '$graph_params_dict_str';
                                ")
    table = Table(query) #must create a TypedTable to access query values
    insert_row = table[1].graph_id
    SQLite.close(db)
    tuple_to_return = (status_message = "SQLite [SimulationSaves: graphs]... INSERT STATUS: [$status] GRAPH_ID: [$insert_row]", insert_row_id = insert_row)
    return tuple_to_return
end

function insertSimulationSQL(sim_params_str::String, graph_adj_matrix_str::String, periods_elapsed::Integer, game_id::Integer, graph_id::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")
    
    status = SQLite.execute(db, "
                                    INSERT INTO simulations
                                    (
                                        'sim_params',
                                        'game_id',
                                        'graph_id',
                                        'graph_adj_matrix',
                                        'periods_elapsed'
                                    )
                                    VALUES
                                    (
                                        '$sim_params_str',
                                        $game_id,
                                        $graph_id,
                                        '$graph_adj_matrix_str',
                                        $periods_elapsed
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
                                        'simulation_id',
                                        'agent'
                                    )
                                    VALUES
                                        $values_string;
                            ")
    SQLite.close(db)
    return "SQLite [SimulationSaves: agents]... INSERT STATUS: [$status]"
end

function queryGameSQL()
    db = SQLite.DB("SimulationSaves.sqlite")
    SQLite.close(db)
end

function queryGraphSQL()
    db = SQLite.DB("SimulationSaves.sqlite")
    SQLite.close(db)
end

function querySimulationSQL()
    db = SQLite.DB("SimulationSaves.sqlite")
    SQLite.close(db)
end

function queryAgentsSQL()
    db = SQLite.DB("SimulationSaves.sqlite")
    SQLite.close(db)
end