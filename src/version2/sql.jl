using SQLite

function initSQL()
    #create or connect to database
    db = SQLite.DB("SimulationSaves.sqlite")

    #create 'games' table (currently only the "bargaining game" exists)
    SQLite.execute(db, "CREATE TABLE IF NOT EXISTS games
                        (
                            'game_id' INTEGER PRIMARY KEY,
                            'name' TEXT NOT NULL UNIQUE,
                            'payoff_matrix' TEXT
                        );")

    #create 'graphs' table which stores the graph types with their specific parameters (parameters might go in different table?)
    SQLite.execute(db, "CREATE TABLE IF NOT EXISTS graphs
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
                            'external_λ' REAL DEFAULT NULL
                        );")

    #create simulations table which contains information specific to each simulation
    SQLite.execute(db, "CREATE TABLE IF NOT EXISTS simulations
                        (
                            'simulation_id' INTEGER PRIMARY KEY,
                            'description' TEXT NOT NULL UNIQUE,
                            'sim_params' TEXT NOT NULL,
                            'game_id' INTEGER NOT NULL,
                            'graph_id' INTEGER NOT NULL,
                            'graph_adj_matrix' TEXT NOT NULL,
                            'periods_elapsed' INTEGER NOT NULL,
                            FOREIGN KEY (game_id)
                                REFERENCES games (game_id),
                            FOREIGN KEY (graph_id)
                                REFERENCES graphs (graph_id)
                        );")

    #create agents table which contains json strings of agent types (with memory states). FK points to specific simulation
    SQLite.execute(db, "CREATE TABLE IF NOT EXISTS agents
                        (
                            'agent_id' INTEGER PRIMARY KEY,
                            'simulation_id' INTEGER NOT NULL,
                            'agent' TEXT NOT NULL,
                            FOREIGN KEY (simulation_id)
                                REFERENCES simulations (simulation_id)
                        );")
end

function insertGameSQL(name::String, payoff_matrix_str::String)
    db = SQLite.DB("SimulationSaves.sqlite")
    result = DBInterface.execute(db, "INSERT INTO games
                                (
                                    'name',
                                    'payoff_matrix'
                                )
                                VALUES
                                (
                                    '$name',
                                    '$payoff_matrix_str'
                                );")
    status = result.status.x
    row_id = result.stmt.id
    return "SQLite [SimulationSaves: games] insert status: $status"
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

    result = DBInterface.execute(db, "INSERT INTO graphs
                                (
                                    $insert_string_columns
                                )
                                VALUES
                                (
                                    $insert_string_values
                                );")
    status = result.status.x
    row_id = result.stmt.id
    return "SQLite [SimulationSaves: graphs] insert status: $status"
end

function insertSimulationSQL(description::String, sim_params_str::String, graph_adj_matrix_str::String, periods_elapsed::Integer)
    db = SQLite.DB("SimulationSaves.sqlite")

    game_id_query = 1
    graph_id_query = 1
    
    result = DBInterface.execute(db, "INSERT INTO simulations
                                (
                                    'description',
                                    'sim_params',
                                    'game_id',
                                    'graph_id',
                                    'graph_adj_matrix',
                                    'periods_elapsed'
                                )
                                VALUES
                                (
                                    '$description',
                                    '$sim_params_str',
                                    $game_id_query,
                                    $graph_id_query,
                                    '$graph_adj_matrix_str',
                                    $periods_elapsed
                                );")
    status = result.status.x
    row_id = result.stmt.id
    return "SQLite [SimulationSaves: simulations] insert status: $status"
end

function insertAgentsSQL(agent_list::Vector{String})
    db = SQLite.DB("SimulationSaves.sqlite")
    query_simulation_id = 1

    values_string = "" #construct a values string to insert multiple agents into db table
    for agent in agent_list
        values_string *= "($query_simulation_id, '$agent'), "
    end
    values_string = rstrip(values_string, [' ', ','])
    println(values_string)
     
    status = SQLite.execute(db, "INSERT INTO agents
                            (
                                'simulation_id',
                                'agent'
                            )
                            VALUES
                                $values_string
                            ;")
    return "SQLite [SimulationSaves: agents] insert status: $status"
end

function queryGameSQL()
    db = SQLite.DB("SimulationSaves.sqlite")
end

function queryGraphSQL()
    db = SQLite.DB("SimulationSaves.sqlite")
end

function querySimulationSQL()
    db = SQLite.DB("SimulationSaves.sqlite")
end

function queryAgentsSQL()
    db = SQLite.DB("SimulationSaves.sqlite")
end