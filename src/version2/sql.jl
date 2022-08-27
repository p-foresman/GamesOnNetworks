using SQLite

function initSQL()
    #create or connect to database
    db = SQLite.DB("SimulationSaves.sqlite")

    #create 'games' table (currently only the "bargaining game" exists)
    SQLite.execute(db, "CREATE TABLE IF NOT EXISTS games
                        (
                            'game_id' INTEGER PRIMARY KEY,
                            'name' TEXT NOT NULL UNIQUE,
                            'payoff_matrix' TEXT,
                        );")

    #create 'graphs' table which stores the graph types with their specific parameters (parameters might go in different table?)
    SQLite.execute(db, "CREATE TABLE IF NOT EXISTS graphs
                        (
                            'graph_id' INTEGER PRIMARY KEY,
                            'type' TEXT NOT NULL,
                            'graph_params_dict TEXT NOT NULL'
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
                            FOREGN KEY (graph_id)
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

function insertGameSQL(name::String, payoff_matrix::String)
end

function insertGraphSQL(type::String, graph_params_dict::String, db_params_dict::Dict{String, Real})
end

function insertSimulationSQL(description::String, sim_params::String, graph_adj_matrix::String, periods_elapsed::Integer)
end

function insertAgentSQL(agent::String)
end

function queryGameSQL()
end

function queryGraphSQL()
end

function querySimulationSQL()
end

function queryAgentsSQL()
end