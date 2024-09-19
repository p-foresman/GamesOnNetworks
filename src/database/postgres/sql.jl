function add_test_table()
    db = Database()
    LibPQ.execute(db, "create table if not exists test (id integer primary key generated always as identity, val integer);")
    LibPQ.close(db)
end

function add_test_val(val::Int)
    db = Database()
    LibPQ.execute(db, "insert into test (val) values ($val);")
    LibPQ.close(db)
end


Database() = LibPQ.Connection("dbname=$(SETTINGS.db_name)
                            user=$(SETTINGS.db_info["user"])
                            host=$(SETTINGS.db_info["host"])
                            port=$(SETTINGS.db_info["port"])
                            password=$(SETTINGS.db_info["password"])")

function execute_init_full()
    #create or connect to database
    db = Database()

    #create 'games' table (currently only the "bargaining game" exists)
    LibPQ.execute(db, "
                            CREATE TABLE IF NOT EXISTS games
                            (
                                game_id integer primary key generated always as identity,
                                game_name TEXT NOT NULL,
                                game TEXT NOT NULL,
                                payoff_matrix_size TEXT NOT NULL,
                                UNIQUE(game_name, game)
                            );
                    ")

    #create 'graphs' table which stores the graph types with their specific parameters (parameters might go in different table?)
    LibPQ.execute(db, "
                            CREATE TABLE IF NOT EXISTS graphs
                            (
                                graph_id integer primary key generated always as identity,
                                graph TEXT NOT NULL,
                                graph_type TEXT NOT NULL,
                                graph_params TEXT NOT NULL,
                                λ REAL DEFAULT NULL,
                                β REAL DEFAULT NULL,
                                α REAL DEFAULT NULL,
                                blocks INTEGER DEFAULT NULL,
                                p_in REAL DEFAULT NULL,
                                p_out REAL DEFAULT NULL,
                                UNIQUE(graph, graph_params)
                            );
                    ")

    #create 'sim_params' table which contains information specific to each simulation
    LibPQ.execute(db, "
                            CREATE TABLE IF NOT EXISTS sim_params
                            (
                                sim_params_id integer primary key generated always as identity,
                                number_agents INTEGER NOT NULL,
                                memory_length INTEGER NOT NULL,
                                error REAL NOT NULL,
                                sim_params TEXT NOT NULL,
                                use_seed BOOLEAN NOT NULL,
                                UNIQUE(sim_params, use_seed)
                            );
                    ")

    LibPQ.execute(db, "
                            CREATE TABLE IF NOT EXISTS starting_conditions
                            (
                                starting_condition_id integer primary key generated always as identity,
                                name TEXT NOT NULL,
                                starting_condition TEXT NOT NULL,
                                UNIQUE(name, starting_condition)
                            );
                    ")

    LibPQ.execute(db, "
                            CREATE TABLE IF NOT EXISTS stopping_conditions
                            (
                                stopping_condition_id integer primary key generated always as identity,
                                name TEXT NOT NULL,
                                stopping_condition TEXT NOT NULL,
                                UNIQUE(name, stopping_condition)
                            );
                    ")

    #create 'sim_groups' table to group simulations and give the groups an easy-access description (version control is handled with the prev_simulation_id column in the individual simulation saves)
    LibPQ.execute(db, "
                            CREATE TABLE IF NOT EXISTS sim_groups
                            (
                                sim_group_id integer primary key generated always as identity,
                                description TEXT DEFAULT NULL,
                                UNIQUE(description)
                            );
                    ")

    #create 'simulations' table which contains information specific to each simulation
    LibPQ.execute(db, "
                            CREATE TABLE IF NOT EXISTS simulations
                            (
                                simulation_id integer primary key generated always as identity,
                                simulation_uuid TEXT NOT NULL,
                                sim_group_id INTEGER DEFAULT NULL,
                                prev_simulation_uuid TEXT DEFAULT NULL,
                                game_id INTEGER NOT NULL,
                                graph_id INTEGER NOT NULL,
                                sim_params_id INTEGER NOT NULL,
                                starting_condition_id INTEGER NOT NULL,
                                stopping_condition_id INTEGER NOT NULL,
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
                                FOREIGN KEY (starting_condition_id)
                                    REFERENCES starting_conditions (starting_condition_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (stopping_condition_id)
                                    REFERENCES stopping_conditions (stopping_condition_id)
                                    ON DELETE CASCADE,
                                UNIQUE(simulation_uuid)
                            );
                    ")

    #create 'agents' table which contains json strings of agent types (with memory states). FK points to specific simulation
    LibPQ.execute(db, "
                            CREATE TABLE IF NOT EXISTS agents
                            (
                                agent_id integer primary key generated always as identity,
                                simulation_uuid TEXT NOT NULL,
                                agent TEXT NOT NULL,
                                FOREIGN KEY (simulation_uuid)
                                    REFERENCES simulations (simulation_uuid)
                                    ON DELETE CASCADE
                            );
                    ")
    LibPQ.close(db)
end

#this DB only needs tables for simulations and agents. These will be collected into the master DB later
function execute_init_temp(db_filepath::String)
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
                                starting_condition_id INTEGER NOT NULL,
                                stopping_condition_id INTEGER NOT NULL,
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
                                FOREIGN KEY (starting_condition_id)
                                    REFERENCES starting_conditions (starting_condition_id)
                                    ON DELETE CASCADE,
                                FOREIGN KEY (stopping_condition_id)
                                    REFERENCES stopping_conditions (stopping_condition_id)
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



function execute_insert_game(game_name::String, game::String, payoff_matrix_size::String)
    db = Database()
    result = LibPQ.execute(db, "
                                    INSERT INTO games
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
                                    )
                                    ON CONFLICT (game_name, game) DO UPDATE
                                        SET game_name = games.game_name
                                    RETURNING game_id;
                            ")
    # query = LibPQ.execute(db, "
    #                                     SELECT game_id
    #                                     FROM games
    #                                     WHERE game_name = '$game_name'
    #                                     AND game = '$game';
    #                             ")
    df = DataFrame(result)
    println(df)
    insert_row = df[1, :game_id]
    LibPQ.close(db)
    return (status_message = "PostgreSQL [$(SETTINGS.db_name): games]... INSERT STATUS: [OK] GAME_ID: [$insert_row]]", insert_row_id = insert_row)
end

function execute_insert_graph(graph::String, graph_type::String, graph_params_str::String, db_graph_params_dict::Dict{Symbol, Any})
    db = Database()
    insert_string_columns = "graph, graph_type, graph_params, "
    insert_string_values = "'$graph', '$graph_type', '$graph_params_str', "
    for (param, value) in db_graph_params_dict
        if value !== nothing
            insert_string_columns *= "'$param', "
            insert_string_values *= "$value, "
        end
    end
    insert_string_columns = rstrip(insert_string_columns, [' ', ',']) #strip off the comma and space at the end of the string
    insert_string_values = rstrip(insert_string_values, [' ', ','])

    result = LibPQ.execute(db, "
                                    INSERT INTO graphs
                                    (
                                        $insert_string_columns
                                    )
                                    VALUES
                                    (
                                        $insert_string_values
                                    )
                                    ON CONFLICT (graph, graph_params) DO UPDATE
                                        SET graph_type = graphs.graph_type
                                    RETURNING graph_id;
                            ")
    # query = LibPQ.execute(db, "
    #                                     SELECT graph_id
    #                                     FROM graphs
    #                                     WHERE graph = '$graph'
    #                                     AND graph_params = '$graph_params_str';
    #                             ")
    df = DataFrame(result)
    insert_row = df[1, :graph_id]
    LibPQ.close(db)
    return (status_message = "PostgreSQL [$(SETTINGS.db_name): graphs]... INSERT STATUS: [OK] GRAPH_ID: [$insert_row]]", insert_row_id = insert_row)
end

function execute_insert_sim_params(sim_params::SimParams, sim_params_str::String, use_seed::String)
    db = Database()
    result = LibPQ.execute(db, "
                                    INSERT INTO sim_params
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
                                        '$use_seed'
                                    )
                                    ON CONFLICT (sim_params, use_seed) DO UPDATE
                                        SET use_seed = sim_params.use_seed
                                    RETURNING sim_params_id;
                            ")
    # query = DBInterface.execute(db, "
    #                                     SELECT sim_params_id
    #                                     FROM sim_params
    #                                     WHERE sim_params = '$sim_params_str'
    #                                     AND use_seed = $use_seed;
    #                             ")
    df = DataFrame(result) #must create a DataFrame to acces query data
    insert_row = df[1, :sim_params_id]
    LibPQ.close(db)
    return (status_message = "PostgreSQL [$(SETTINGS.db_name): sim_params]... INSERT STATUS: [OK] SIM_PARAMS_ID: [$insert_row]]", insert_row_id = insert_row)
end

function execute_insert_starting_condition(starting_condition_name::String, starting_condition_str::String)
    db = Database()
    result = LibPQ.execute(db, "
                                    INSERT INTO starting_conditions
                                    (
                                        name,
                                        starting_condition
                                    )
                                    VALUES
                                    (
                                        '$starting_condition_name',
                                        '$(starting_condition_str)'
                                    )
                                    ON CONFLICT (name, starting_condition) DO UPDATE
                                        SET name = starting_conditions.name
                                    RETURNING starting_condition_id;
                            ")
    # query = DBInterface.execute(db, "
    #                                     SELECT starting_condition_id
    #                                     FROM starting_conditions
    #                                     WHERE starting_condition = '$starting_condition_str';
    #                             ")
    df = DataFrame(result) #must create a DataFrame to acces query data
    insert_row = df[1, :starting_condition_id]
    LibPQ.close(db)
    return (status_message = "PostgreSQL [$(SETTINGS.db_name): starting_conditions]... INSERT STATUS: [OK] STARTING_CONDITION_ID: [$insert_row]]", insert_row_id = insert_row)
end

function execute_insert_stopping_condition(stopping_condition_name::String, stopping_condition_str::String)
    db = Database()
    result = LibPQ.execute(db, "
                                    INSERT INTO stopping_conditions
                                    (
                                        name,
                                        stopping_condition
                                    )
                                    VALUES
                                    (
                                        '$stopping_condition_name',
                                        '$(stopping_condition_str)'
                                    )
                                    ON CONFLICT (name, stopping_condition) DO UPDATE
                                        SET name = stopping_conditions.name
                                    RETURNING stopping_condition_id;
                            ")
    # query = DBInterface.execute(db, "
    #                                     SELECT stopping_condition_id
    #                                     FROM stopping_conditions
    #                                     WHERE stopping_condition = '$stopping_condition_str';
    #                             ")
    df = DataFrame(result) #must create a DataFrame to acces query data
    insert_row = df[1, :stopping_condition_id]
    LibPQ.close(db)
    return (status_message = "PostgreSQL [$(SETTINGS.db_name): stopping_conditions]... INSERT STATUS: [OK] STOPPING_CONDITION_ID: [$insert_row]]", insert_row_id = insert_row)
end

function execute_insert_sim_group(description::String)
    db = Database()
    result = LibPQ.execute(db, "
                                    INSERT INTO sim_groups
                                    (
                                        description
                                    )
                                    VALUES
                                    (
                                        '$description'
                                    )
                                    ON CONFLICT (description) DO UPDATE
                                        SET description = sim_groups.description
                                    RETURNING sim_group_id;
                            ")
    
    # query = DBInterface.execute(db, "
    #                                     SELECT sim_group_id
    #                                     FROM sim_groups
    #                                     WHERE description = '$description'
    #                             ")
    df = DataFrame(result)
    insert_row = df[1, :sim_group_id]
    LibPQ.close(db)
    return (status_message = "PostgreSQL [$(SETTINGS.db_name): sim_groups]... INSERT STATUS: [OK] SIM_GROUP_ID: [$insert_row]]", insert_row_id = insert_row)
end

# function execute_insert_simulation(db, sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, db_id_tuple::NamedTuple{(:game_id, :graph_id, :sim_params_id, :starting_condition_id, :stopping_condition_id), NTuple{5, Int}}, graph_adj_matrix_str::String, rng_state::String, periods_elapsed::Integer)
#     uuid = "$(uuid4())"
    
#     sim_group_id === nothing ? sim_group_id = "NULL" : nothing
#     prev_simulation_uuid === nothing ?  prev_simulation_uuid = "NULL" : nothing

#     # db = SQLite.DB("$db_filepath")
#     # SQLite.busy_timeout(db, 3000)
#     status = SQLite.execute(db, "
#                                     INSERT INTO simulations
#                                     (
#                                         simulation_uuid,
#                                         sim_group_id,
#                                         prev_simulation_uuid,
#                                         game_id,
#                                         graph_id,
#                                         sim_params_id,
#                                         starting_condition_id,
#                                         stopping_condition_id,
#                                         graph_adj_matrix,
#                                         rng_state,
#                                         periods_elapsed
#                                     )
#                                     VALUES
#                                     (
#                                         '$uuid',
#                                         $sim_group_id,
#                                         '$prev_simulation_uuid',
#                                         $(db_id_tuple.game_id),
#                                         $(db_id_tuple.graph_id),
#                                         $(db_id_tuple.sim_params_id),
#                                         $(db_id_tuple.starting_condition_id),
#                                         $(db_id_tuple.stopping_condition_id),
#                                         '$graph_adj_matrix_str',
#                                         '$rng_state',
#                                         $periods_elapsed
#                                 );
#                             ")
#     insert_row = SQLite.last_insert_rowid(db)
#     # SQLite.close(db)
#     tuple_to_return = (status_message = "SQLite [SimulationSaves: simulations]... INSERT STATUS: [$status] SIMULATION_ID: [$insert_row]", insert_row_id = insert_row, uuid = uuid)
#     return tuple_to_return
# end

# function execute_insert_agents(db, simulation_uuid::String, agent_list::Vector{String})
#     # db = SQLite.DB("$db_filepath")
#     # SQLite.busy_timeout(db, 3000)
#     values_string = "" #construct a values string to insert multiple agents into db table
#     for agent in agent_list
#         values_string *= "('$simulation_uuid', '$agent'), "
#     end
#     values_string = rstrip(values_string, [' ', ','])
#     #println(values_string)
     
#     status = SQLite.execute(db, "
#                                     INSERT INTO agents
#                                     (
#                                         simulation_uuid,
#                                         agent
#                                     )
#                                     VALUES
#                                         $values_string;
#                             ")
#     # SQLite.close(db)
#     return (status_message = "SQLite [SimulationSaves: agents]... INSERT STATUS: [$status]")
# end


function execute_insert_simulation_with_agents(sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, db_id_tuple::NamedTuple{(:game_id, :graph_id, :sim_params_id, :starting_condition_id, :stopping_condition_id), NTuple{5, Int}}, graph_adj_matrix_str::String, rng_state::String, periods_elapsed::Integer, agent_list::Vector{String})
    simulation_uuid = "$(uuid4())"
    
    #prepare simulation SQL
    sim_group_id === nothing ? sim_group_id = "NULL" : nothing
    prev_simulation_uuid = prev_simulation_uuid === nothing ?  "null" : "'$prev_simulation_uuid'"

    #prepare agents SQL
    agent_values_string = "" #construct a values string to insert multiple agents into db table
    for agent in agent_list
        agent_values_string *= "('$simulation_uuid', '$agent'), "
    end
    agent_values_string = rstrip(agent_values_string, [' ', ','])

    #open DB connection
    db = Database()

    #first insert simulation with simulation_uuid
    result = LibPQ.execute(db, "
                                    INSERT INTO simulations
                                    (
                                        simulation_uuid,
                                        sim_group_id,
                                        prev_simulation_uuid,
                                        game_id,
                                        graph_id,
                                        sim_params_id,
                                        starting_condition_id,
                                        stopping_condition_id,
                                        graph_adj_matrix,
                                        rng_state,
                                        periods_elapsed
                                    )
                                    VALUES
                                    (
                                        '$simulation_uuid',
                                        $sim_group_id,
                                        $prev_simulation_uuid,
                                        $(db_id_tuple.game_id),
                                        $(db_id_tuple.graph_id),
                                        $(db_id_tuple.sim_params_id),
                                        $(db_id_tuple.starting_condition_id),
                                        $(db_id_tuple.stopping_condition_id),
                                        '$graph_adj_matrix_str',
                                        '$rng_state',
                                        $periods_elapsed
                                    );

                                    INSERT INTO agents
                                    (
                                        simulation_uuid,
                                        agent
                                    )
                                    VALUES
                                        $agent_values_string;
                            ")

    LibPQ.close(db)

    return (status_message = "PostgreSQL [SimulationSaves: simulations & agents]... SIMULATION INSERT STATUS: [OK] AGENTS INSERT STATUS: [OK] SIMULATION_UUID: [$simulation_uuid]", simulation_uuid = simulation_uuid)
end


function execute_query_games(db_filepath::String, game_id::Integer)
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

function execute_query_graphs(db_filepath::String, graph_id::Integer)
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

function execute_query_sim_params(db_filepath::String, sim_params_id::Integer)
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

function execute_query_starting_conditions(db_filepath::String, starting_condition_id::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM starting_conditions
                                        WHERE starting_condition_id = $starting_condition_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

function execute_query_stopping_conditions(db_filepath::String, stopping_condition_id::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT *
                                        FROM stopping_conditions
                                        WHERE stopping_condition_id = $stopping_condition_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

function execute_query_sim_groups(db_filepath::String, sim_group_id::Integer)
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

function execute_query_simulations(db_filepath::String, simulation_id::Integer)
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

function execute_query_agents(db_filepath::String, simulation_id::Integer)
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

function execute_query_simulations_for_restore(db_filepath::String, simulation_id::Integer)
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
                                            games.payoff_matrix_size,
                                            starting_conditions.starting_condition,
                                            stopping_conditions.stopping_condition
                                        FROM simulations
                                        INNER JOIN games USING(game_id)
                                        INNER JOIN graphs USING(graph_id)
                                        INNER JOIN sim_params USING(sim_params_id)
                                        INNER JOIN starting_conditions USING(starting_condition_id)
                                        INNER JOIN stopping_conditions USING(stopping_condition_id)
                                        WHERE simulations.simulation_id = $simulation_id;
                                ")
    df = DataFrame(query) #must create a DataFrame to acces query data
    SQLite.close(db)
    return df
end

function execute_query_agents_for_restore(db_filepath::String, simulation_id::Integer)
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


#NOTE: FIX
# function querySimulationsByGroup(db_filepath::String, sim_group_id::Int)
#     db = SQLite.DB("$db_filepath")
#     SQLite.busy_timeout(db, 3000)
#     query = DBInterface.execute(db, "
#                                         SELECT
#                                             simulations.simulation_id,
#                                             simulations.sim_group_id,
#                                             simulations.sim_params_id,
#                                             simulations.graph_adj_matrix,
#                                             simulations.use_seed,
#                                             simulations.rng_state,
#                                             simulations.periods_elapsed,
#                                             games.game,
#                                             games.payoff_matrix_size,
#                                             graphs.graph_params
#                                         FROM simulations
#                                         INNER JOIN games USING(game_id)
#                                         INNER JOIN graphs USING(graph_id)
#                                         INNER JOIN sim_params USING(sim_params_id)
#                                         WHERE simulations.sim_group_id = $sim_group_id
#                                 ")
#     df = DataFrame(query) #must create a DataFrame to acces query data
#     SQLite.close(db)
#     return df
# end

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

function execute_delete_simulation(db_filepath::String, simulation_id::Int)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    SQLite.execute(db, "PRAGMA foreign_keys = ON;") #turn on foreign key support to allow cascading deletes
    status = SQLite.execute(db, "DELETE FROM simulations WHERE simulation_id = $simulation_id;")
    SQLite.close(db)
    return status
end


# Merge two SQLite files. These db files MUST have the same schema
function execute_merge_full(db_filepath_master::String, db_filepath_merger::String)
    db = SQLite.DB("$db_filepath_master")
    SQLite.busy_timeout(db, 5000)
    SQLite.execute(db, "ATTACH DATABASE '$db_filepath_merger' as merge_db;")
    SQLite.execute(db, "INSERT OR IGNORE INTO games(game_name, game, payoff_matrix_size) SELECT game_name, game, payoff_matrix_size FROM merge_db.games;")
    SQLite.execute(db, "INSERT OR IGNORE INTO graphs(graph, graph_type, graph_params, λ, β, α, blocks, p_in, p_out) SELECT graph, graph_type, graph_params, λ, β, α, blocks, p_in, p_out FROM merge_db.graphs;")
    SQLite.execute(db, "INSERT OR IGNORE INTO sim_params(number_agents, memory_length, error, sim_params, use_seed) SELECT number_agents, memory_length, error, sim_params, use_seed FROM merge_db.sim_params;")
    SQLite.execute(db, "INSERT OR IGNORE INTO starting_conditions(name, starting_condition) SELECT name, starting_condition FROM merge_db.starting_conditions;")
    SQLite.execute(db, "INSERT OR IGNORE INTO stopping_conditions(name, stopping_condition) SELECT name, stopping_condition FROM merge_db.stopping_conditions;")
    SQLite.execute(db, "INSERT OR IGNORE INTO sim_groups(description) SELECT description FROM merge_db.sim_groups;")
    SQLite.execute(db, "INSERT INTO simulations(simulation_uuid, sim_group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, periods_elapsed) SELECT simulation_uuid, sim_group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, periods_elapsed FROM merge_db.simulations;")
    SQLite.execute(db, "INSERT INTO agents(simulation_uuid, agent) SELECT simulation_uuid, agent from merge_db.agents;")
    SQLite.execute(db, "DETACH DATABASE merge_db;")
    SQLite.close(db)
    return nothing
end

# Merge temp distributed DBs into master DB.
function execute_merge_temp(db_filepath_master::String, db_filepath_merger::String)
    db = SQLite.DB("$db_filepath_master")
    SQLite.busy_timeout(db, rand(1:5000)) #this caused issues on cluster (.nfsXXXX files were being created. Does this stop the database connection from being closed?) NOTE: are all of these executes separate writes? can we put them all into one???
    SQLite.execute(db, "ATTACH DATABASE '$db_filepath_merger' as merge_db;")
    SQLite.execute(db, "INSERT OR IGNORE INTO simulations(simulation_uuid, sim_group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, periods_elapsed) SELECT simulation_uuid, sim_group_id, prev_simulation_uuid, game_id, graph_id, sim_params_id, starting_condition_id, stopping_condition_id, graph_adj_matrix, rng_state, periods_elapsed FROM merge_db.simulations;")
    SQLite.execute(db, "INSERT OR IGNORE INTO agents(simulation_uuid, agent) SELECT simulation_uuid, agent from merge_db.agents;")
    SQLite.execute(db, "DETACH DATABASE merge_db;")
    SQLite.close(db)
    return nothing
end




function querySimulationsForBoxPlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length::Integer, error::Float64, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Int)
    graph_ids_sql = ""
    if graph_ids !== nothing
        length(graph_ids) == 1 ? graph_ids_sql *= "AND simulations.graph_id = $(graph_ids[1])" : graph_ids_sql *= "AND simulations.graph_id IN $(Tuple(graph_ids))"
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
                                                graphs.graph,
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
    error_set = Set([])
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in df[:, :graph_id]]) : nothing

    for graph_id in graph_ids
        filtered_df = filter(:graph_id => id -> id == graph_id, df)
        if nrow(filtered_df) < sample_size
            push!(error_set, filtered_df[1, :graph])
        end
    end
    if !isempty(error_set)
        throw(ErrorException("Not enough samples for the following graphs: $error_set"))
    else
        return df
    end
end


function querySimulationsForMemoryLengthLinePlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
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


    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
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
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
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
    function graphsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    memory_length_list === nothing ? memory_length_list = Set([memory_length for memory_length in memoryLengthsDF()[:, :memory_length]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

    SQLite.close(db)

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




function querySimulationsForNumberAgentsLinePlot(db_filepath::String; game_id::Integer, number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing, memory_length::Integer, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
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


    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
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
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
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
    function graphsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

    SQLite.close(db)

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


function query_simulations_for_transition_time_vs_memory_sweep(db_filepath::String;
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

    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
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
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
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
    function graphsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

    SQLite.close(db)

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



function query_simulations_for_transition_time_vs_population_sweep(db_filepath::String;
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

    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
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
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                graphs.λ,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
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
    function graphsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

    SQLite.close(db)

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


function query_simulations_for_transition_time_vs_population_stopping_condition(db_filepath::String;
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

    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
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
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
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
    function graphsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

    SQLite.close(db)

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



function query_simulations_for_transition_time_vs_memory_length_stopping_condition(db_filepath::String;
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

    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
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
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
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
    function graphsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

    SQLite.close(db)

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



function querySimulationsForTimeSeries(db_filepath::String;sim_group_id::Integer)
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)

    #query the simulation info (only need one row since each entry in the timeseries group will have the same info)
    #separate this from agent query to save memory, as this query could be very memory intensive
    query_sim_info = DBInterface.execute(db, "
                                                SELECT
                                                    simulations.simulation_id,
                                                    sim_params.sim_params,
                                                    sim_params.number_agents,
                                                    sim_params.memory_length,
                                                    sim_params.error,
                                                    graphs.graph_id,
                                                    graphs.graph,
                                                    graphs.graph_params,
                                                    games.game_name,
                                                    games.game,
                                                    games.payoff_matrix_size
                                                FROM simulations
                                                INNER JOIN sim_params USING(sim_params_id)
                                                INNER JOIN games USING(game_id)
                                                INNER JOIN graphs USING(graph_id)
                                                WHERE simulations.sim_group_id = $sim_group_id
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
                                                    WHERE simulations.sim_group_id = $sim_group_id
                                                    ORDER BY simulations.periods_elapsed ASC
                                                ")
    agent_df = DataFrame(query_agent_info)
    SQLite.close(db)

    return (sim_info_df = sim_info_df, agent_df = agent_df)
end




function query_simulations_for_noise_structure_heatmap(db_filepath::String;
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
        length(mean_degrees) == 1 ? mean_degrees_sql *= "AND graphs.λ = $(mean_degrees[1])" : mean_degrees_sql *= "AND graphs.λ IN $(Tuple(mean_degrees))"
    end
    # graph_params_sql = "AND ("
    # if graph_params !== nothing
    #     for graph in graph_params
    #         graph_params_sql *= "("
    #         for (param, value) in graph
    #             graph_params_sql *= "graphs.$(string(param)) = $(value === nothing ? "null" : value) AND "
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
                graph_params_sql *= "graphs.$(string(param)) = '$(value)' AND "
            end
            graph_params_sql = rstrip(graph_params_sql, collect(" AND "))
            graph_params_sql *= ") OR"
        end
        graph_params_sql = rstrip(graph_params_sql, collect(" OR"))
        graph_params_sql *= ")"
    end
    
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    query = DBInterface.execute(db, "
                                        SELECT * FROM (
                                            SELECT
                                                ROW_NUMBER() OVER ( 
                                                    PARTITION BY simulations.graph_id, sim_params.error, graphs.λ
                                                    ORDER BY sim_params.error, graphs.λ
                                                ) RowNum,
                                                simulations.simulation_id,
                                                sim_params.error,
                                                simulations.periods_elapsed,
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_type,
                                                graphs.graph_params,
                                                graphs.λ,
                                                graphs.β,
                                                graphs.α,
                                                graphs.p_in,
                                                graphs.p_out,
                                                games.game_name
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
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
    # graphsDF() = DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphs"))
    # meanDegreesDF() = DataFrame(DBInterface.execute(db, "SELECT λ FROM graphs"))

    # error_set = []
    # errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    # graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing
    # mean_degrees === nothing ? mean_degrees = Set([λ for λ in numberAgentsDF()[:, :λ]]) : nothing


    # SQLite.close(db)

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


function query_simulations_for_transition_time_vs_graph_params_sweep(db_filepath::String;
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
            graph_params_sql *= "graphs.$(string(param)) = '$(value)' AND "
        end
        graph_params_sql = rstrip(graph_params_sql, collect(" AND "))
        graph_params_sql *= ") OR"
    end
    graph_params_sql = rstrip(graph_params_sql, collect(" OR"))
    graph_params_sql *= ")"


    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
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
                                                graphs.graph_id,
                                                graphs.graph,
                                                graphs.graph_params,
                                                graphs.λ,
                                                graphs.β,
                                                graphs.α,
                                                graphs.p_in,
                                                graphs.p_out,
                                                games.game_name,
                                                simulations.starting_condition_id,
                                                simulations.stopping_condition_id
                                            FROM simulations
                                            INNER JOIN sim_params USING(sim_params_id)
                                            INNER JOIN games USING(game_id)
                                            INNER JOIN graphs USING(graph_id)
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
    function graphsDF() DataFrame(DBInterface.execute(db, "SELECT graph_id, graph FROM graphs")) end
    
    error_set = []
    number_agents_list === nothing ? number_agents_list = Set([number_agents for number_agens in numberAgentsDF()[:, :number_agents]]) : nothing
    errors === nothing ? errors = Set([error for error in errorsDF()[:, :error]]) : nothing
    graph_ids === nothing ? graph_ids = Set([graph_id for graph_id in graphsDF()[:, :graph_id]]) : nothing

    SQLite.close(db)

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