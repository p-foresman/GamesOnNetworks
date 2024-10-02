abstract type DBInfo end

struct PostgresInfo <: DBInfo
    name::String
    user::String
    host::String
    port::String
    password::String
end

struct SQLiteInfo <: DBInfo
    name::String
    filepath::String
end

db_type(database::SQLiteInfo) = "sqlite"
db_type(database::PostgresInfo) = "postgres"

DatabaseIdTuple = NamedTuple{(:game_id, :graph_id, :sim_params_id, :starting_condition_id, :stopping_condition_id), NTuple{5, Int}}


# include sqlite and postgresql specific APIs
include("./sqlite/database_api.jl")
include("./postgres/database_api.jl")


# function barriers to interface with sqlite/postgres-specific functions using configured database in environment variable 'SETTINGS'
DBConnection() = DBConnection(SETTINGS.database)

db_init() = db_init(SETTINGS.database)
db_init(::Nothing) = nothing


db_insert_sim_group(description::String) = db_insert_sim_group(SETTINGS.database, description)
db_insert_sim_group(::Nothing, ::String) = nothing

db_insert_game(game::Game) = db_insert_game(SETTINGS.database, game)
db_insert_game(::Nothing, ::Game) = nothing

db_insert_graph(graph_params::GraphParams) = db_insert_graph(SETTINGS.database, graph_params)
db_insert_graph(::Nothing, ::GraphParams) = nothing

db_insert_sim_params(sim_params::SimParams, use_seed::Bool) = db_insert_sim_params(SETTINGS.database, sim_params, use_seed)
db_insert_sim_params(::Nothing, ::SimParams, ::Bool) = nothing

db_insert_starting_condition(starting_condition::StartingCondition) = db_insert_starting_condition(SETTINGS.database, starting_condition)
db_insert_starting_condition(::Nothing, ::StartingCondition) = nothing

db_insert_stopping_condition(stopping_condition::StoppingCondition) = db_insert_stopping_condition(SETTINGS.database, stopping_condition)
db_insert_stopping_condition(::Nothing, ::StoppingCondition) = nothing

function db_insert_simulation(sim_group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, db_id_tuple::DatabaseIdTuple, agent_graph::AgentGraph, periods_elapsed::Integer, distributed_uuid::Union{String, Nothing} = nothing)
    db_insert_simulation(SETTINGS.database, sim_group_id, prev_simulation_uuid, db_id_tuple, agent_graph, periods_elapsed, distributed_uuid)
end
db_insert_simulation(::Nothing, ::Union{Integer, Nothing}, ::Union{String, Nothing}, ::DatabaseIdTuple, ::AgentGraph, ::Integer, ::Union{String, Nothing}) = nothing


#not sure which method below is better (or if it matters at all). leaning towards second one to keep SETTINGS calls as high in the call stack as possible in an effort to optimize
function db_construct_id_tuple(model::SimModel)
    db_info = SETTINGS.database
    db_id_tuple::DatabaseIdTuple = (
                    game_id = db_insert_game(db_info, game(model)),
                    graph_id = db_insert_graph(db_info, graph_params(model)),
                    sim_params_id = db_insert_sim_params(db_info, sim_params(model), SETTINGS.use_seed),
                    starting_condition_id = db_insert_starting_condition(db_info, starting_condition(model)),
                    stopping_condition_id = db_insert_stopping_condition(db_info, stopping_condition(model))
                    )
    return db_id_tuple
end

function db_construct_id_tuple(db_info::DBInfo, model::SimModel, use_seed::Bool)
    db_id_tuple::DatabaseIdTuple = (
                    game_id = db_insert_game(db_info, game(model)),
                    graph_id = db_insert_graph(db_info, graph_params(model)),
                    sim_params_id = db_insert_sim_params(db_info, sim_params(model), use_seed),
                    starting_condition_id = db_insert_starting_condition(db_info, starting_condition(model)),
                    stopping_condition_id = db_insert_stopping_condition(db_info, stopping_condition(model))
                    )
    return db_id_tuple
end


#NOTE: below currently just for database initialization scripts (very likely a better way to do this!!)
function db_insert_model(model::SimModel)
    db_insert_game(SETTINGS.database, game(model))
    db_insert_graph(SETTINGS.database, graph_params(model))
    db_insert_sim_params(SETTINGS.database, sim_params(model), SETTINGS.use_seed)
    db_insert_starting_condition(SETTINGS.database, starting_condition(model))
    db_insert_stopping_condition(SETTINGS.database, stopping_condition(model))
end

function db_insert_model_data(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition})
    #add validation here??  
    for game in game_list
        for sim_params in sim_params_list
            for graph_params in graph_params_list
                for starting_condition in starting_condition_list
                    for stopping_condition in stopping_condition_list
                    db_insert_game(SETTINGS.database, game)
                    db_insert_graph(SETTINGS.database, graph_params)
                    db_insert_sim_params(SETTINGS.database, sim_params, SETTINGS.use_seed)
                    db_insert_starting_condition(SETTINGS.database, starting_condition)
                    db_insert_stopping_condition(SETTINGS.database, stopping_condition)
                    end
                end
            end
        end
    end
end



# #NOTE: FIX
# function db_restore_model(simulation_id::Integer) #MUST FIX TO USE UUID
#     simulation_df = execute_query_simulations_for_restore(SETTINGS.database, simulation_id)
#     agents_df = execute_query_agents_for_restore(SETTINGS.database, simulation_id)

#     #reproduce SimParams object
#     reproduced_sim_params = JSON3.read(simulation_df[1, :sim_params], SimParams)

#     #reproduce Game object
#     payoff_matrix_size = JSON3.read(simulation_df[1, :payoff_matrix_size], Tuple)
#     payoff_matrix_length = payoff_matrix_size[1] * payoff_matrix_size[2]
#     reproduced_game = JSON3.read(simulation_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], payoff_matrix_length})

#     #reproduced Graph     ###!! dont need to reproduce graph unless the simulation is a pure continuation of 1 long simulation !!###
#     reproduced_graph_params = JSON3.read(simulation_df[1, :graph_params], GraphParams)
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
#     return (game=reproduced_game, sim_params=reproduced_sim_params, graph_params=reproduced_graph_params, meta_graph=reproduced_meta_graph, use_seed=seed_bool, periods_elapsed=simulation_df[1, :periods_elapsed], sim_group_id=simulation_df[1, :sim_group_id])
# end