using JSON3, Random, Graphs, MetaGraphs

include("types.jl")
include("sql.jl")

function pushToDatabase(game::Game, params::SimParams, graph_params_dict::Dict{Symbol, Any}, graph::AbstractGraph, periods_elapsed::Integer, use_seed::Bool)

    initSQL()

    #prepare and instert data for "games" table. No duplicate rows.
    game_name = game.name
    game_json_str = JSON3.write(game)
    payoff_matrix_size = JSON3.write(size(game.payoff_matrix))
    game_insert_result = insertGameSQL(game_name, game_json_str, payoff_matrix_size)
    game_status = game_insert_result.status_message
    game_row_id = game_insert_result.insert_row_id

    #prepare and insert data for "graphs" table. No duplicate rows.
    graph_type = String(graph_params_dict[:type])
    graph_params_string = JSON3.write(graph_params_dict)
    db_params_dict = Dict{Symbol, Any}(:λ => nothing, :k => nothing, :β => nothing, :α => nothing, :communities => nothing, :internal_λ => nothing, :external_λ => nothing) #allows for parameter-based queries
    for param in keys(db_params_dict)
        if haskey(graph_params_dict, param)
            db_params_dict[param] = graph_params_dict[param]
        end
    end
    graph_insert_result = insertGraphSQL(graph_type, graph_params_string, db_params_dict)
    graph_status = graph_insert_result.status_message
    graph_row_id = graph_insert_result.insert_row_id

    #prepare and insert data for "simulations" table. Duplicate rows necessary.
    #description = "test description" Might want a description eventually. removed for now.
    params_json_str = JSON3.write(params)
    adj_matrix_json_str = JSON3.write(Matrix(adjacency_matrix(graph)))
    if use_seed == true
        seed_bool = 1
    else
        seed_bool = 0
    end
    rng_state = copy(Random.default_rng())
    rng_state_json = JSON3.write(rng_state)

    simulation_insert_result = insertSimulationSQL(params, params_json_str, adj_matrix_json_str, periods_elapsed, game_row_id, graph_row_id, seed_bool, rng_state_json)
    simulation_status = simulation_insert_result.status_message
    simulation_row_id = simulation_insert_result.insert_row_id

    #create agents list to insert all agents into "agents" table at once
    agents_list = Vector{String}([])
    for vertex in vertices(graph)
        agent = get_prop(graph, vertex, :agent)
        agent_json_str = JSON3.write(agent) #StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable() defined after struct is defined
        push!(agents_list, agent_json_str)
    end
    agents_status = insertAgentsSQL(agents_list, simulation_row_id)

    return game_status, graph_status, simulation_status, agents_status
end

function restoreFromDatabase(game_name::String, graph_params::Dict{Symbol, Any}, number_agents::Integer, memory_length::Integer, error::Float64)
    simulation_df = queryForSimReproduction(game_name, graph_params, number_agents, memory_length, error) #all returns from queries are DataFrames
    
    #reproduce SimParams object
    reproduced_params = JSON3.read(simulation_df[1, :sim_params], SimParams)

    #reproduce Game object
    payoff_matrix_size = JSON3.read(simulation_df[1, :payoff_matrix_size], Tuple)
    println(simulation_df[1, :game])
    reproduced_game = JSON3.read(simulation_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2]})

    #reproduced Graph
    

    return reproduced_params, reproduced_game
end


#parse an adjacency matrix encoded in a string that's pulled from the DB into a matrix to rebuild graph instance
function adjMatrixStringParser(db_matrix_string::String)
    new_vector = JSON3.read(db_matrix_string)
    size = Int64(sqrt(length(new_vector))) #will always be a perfect square due to matrix being adjacency matrix
    new_matrix = reshape(new_vector, (size, size)) #reshape parsed vector into matrix (this result can be fed into the SimpleGraph() function)
    return new_matrix
end

#parse a payoff matrix encoded in a string that's pulled from the DB into a Matrix{Tuple{Int8, Int8}} to rebuild game instance
function payoffMatrixStringParser(db_matrix_string)
    new_vector = JSON3.read(db_matrix_string)
    tuple_vector = Vector{Tuple{Int8, Int8}}([])
    for index in new_vector
        new_tuple = Tuple{Int8, Int8}([index[1], index[2]])
        push!(tuple_vector, new_tuple)
    end
    size = Int64(sqrt(length(tuple_vector))) #NEED TO MAKE THIS SOMEHOW FIND DIMENSIONS SINCE PAYOFF MATRICES DONT HAVE TO BE SQUARE
    new_matrix = reshape(tuple_vector, (size, size))
    return new_matrix
end