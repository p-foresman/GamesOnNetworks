module Database

import ..GraphsExt

using
    ..Model,
    DataFrames,
    JSON3,
    UUIDs

abstract type DBInfo end

struct PostgresInfo <: DBInfo
    name::String
    user::String
    host::String
    port::String
    password::String
end

struct SQLiteInfo <: DBInfo
    name::String #NOTE: make this optional
    filepath::String
end

type(database::SQLiteInfo) = "sqlite"
type(database::PostgresInfo) = "postgres"
name(database::DBInfo) = getfield(database, :name)

DatabaseIdTuple = NamedTuple{(:game_id, :graph_id, :sim_params_id, :starting_condition_id, :stopping_condition_id), NTuple{5, Int}}


# include sqlite and postgresql specific APIs
include("./sqlite/database_api.jl")
# include("./postgres/database_api.jl")


# function barriers to interface with sqlite/postgres-specific functions using configured database in environment variable 'GamesOnNetworks.SETTINGS'

"""
    DB(;kwargs...)

Create a connection to the configured database.
"""
DB(;kwargs...) = DB(GamesOnNetworks.SETTINGS.database, kwargs...)

"""
    db_execute(sql::SQL)

Quick method to execute SQL on the configured database.
"""
function db_execute(sql::SQL)
    db = DB()
    result = db_execute(db, sql)
    db_close(db)
    return result
end

"""
    db_query(sql::SQL)

Quick method to make a query on the configured database. Returns a DataFrame containing results.
"""
function db_query(sql::SQL)
    db = DB()
    query = DataFrame(db_execute(db, sql))
    db_close(db)
    return query
end
# db_begin_transaction() = db_begin_transaction(GamesOnNetworks.SETTINGS.database)
# db_close(db::SQLiteDB) = SQLite.close(db)
# db_commit_transaction(db::SQLiteDB) = SQLite.commit(db)

db_init() = db_init(GamesOnNetworks.SETTINGS.database)
db_init(::Nothing) = nothing


db_insert_sim_group(description::String) = db_insert_sim_group(GamesOnNetworks.SETTINGS.database, description)
db_insert_sim_group(::Nothing, ::String) = nothing

db_insert_game(game::Game) = db_insert_game(GamesOnNetworks.SETTINGS.database, game)
db_insert_game(::Nothing, ::Game) = nothing

db_insert_graph(graphmodel::GraphModel) = db_insert_graph(GamesOnNetworks.SETTINGS.database, graphmodel)
db_insert_graph(::Nothing, ::GraphModel) = nothing

db_insert_sim_params(simparams::SimParams, use_seed::Bool) = db_insert_sim_params(GamesOnNetworks.SETTINGS.database, simparams, use_seed)
db_insert_sim_params(::Nothing, ::SimParams, ::Bool) = nothing

# db_insert_starting_condition(startingcondition::StartingCondition) = db_insert_starting_condition(GamesOnNetworks.SETTINGS.database, startingcondition)
# db_insert_starting_condition(::Nothing, ::StartingCondition) = nothing

# db_insert_stopping_condition(stoppingcondition::StoppingCondition) = db_insert_stopping_condition(GamesOnNetworks.SETTINGS.database, stoppingcondition)
# db_insert_stopping_condition(::Nothing, ::StoppingCondition) = nothing

# function db_insert_simulation(group_id::Union{Integer, Nothing}, prev_simulation_uuid::Union{String, Nothing}, db_id_tuple::DatabaseIdTuple, agentgraph::AgentGraph, period::Integer, distributed_uuid::Union{String, Nothing} = nothing)
#     db_insert_simulation(GamesOnNetworks.SETTINGS.database, GamesOnNetworks.SETTINGS.use_seed, group_id, prev_simulation_uuid, db_id_tuple, agentgraph, period, distributed_uuid)
# end
# db_insert_simulation(::Nothing, ::Union{Integer, Nothing}, ::Union{String, Nothing}, ::DatabaseIdTuple, ::AgentGraph, ::Integer, ::Union{String, Nothing}) = nothing


#not sure which method below is better (or if it matters at all). leaning towards second one to keep GamesOnNetworks.SETTINGS calls as high in the call stack as possible in an effort to optimize
# function db_construct_id_tuple(model::SimModel)
#     db_info = GamesOnNetworks.SETTINGS.database
#     db_id_tuple::DatabaseIdTuple = (
#                     game_id = db_insert_game(db_info, game(model)),
#                     graph_id = db_insert_graphmodel(db_info, graphmodel(model)),
#                     sim_params_id = db_insert_simparams(db_info, simparams(model), GamesOnNetworks.SETTINGS.use_seed),
#                     starting_condition_id = db_insert_startingcondition(db_info, startingcondition(model)),
#                     stopping_condition_id = db_insert_stoppingcondition(db_info, stoppingcondition(model))
#                     )
#     return db_id_tuple
# end

# function db_construct_id_tuple(db_info::DBInfo, model::SimModel, use_seed::Bool)
#     db_id_tuple::DatabaseIdTuple = (
#                     game_id = db_insert_game(db_info, game(model)),
#                     graph_id = db_insert_graphmodel(db_info, graphmodel(model)),
#                     sim_params_id = db_insert_simparams(db_info, simparams(model), use_seed),
#                     starting_condition_id = db_insert_startingcondition(db_info, startingcondition(model)),
#                     stopping_condition_id = db_insert_stoppingcondition(db_info, stoppingcondition(model))
#                     )
#     return db_id_tuple
# end


function db_insert_model(model::SimModel; model_id::Union{Nothing, Integer}=nothing) #NOTE: use_seed needs to be more thought out here. Should it even be included in a model? (probably not, but in a simulation, YES!)
    return db_insert_model(GamesOnNetworks.SETTINGS.database, model, model_id=model_id)
end

function db_has_incomplete_simulations()
    return db_has_incomplete_simulations(GamesOnNetworks.SETTINGS.database)
end

function db_collect_temp(directory_path::String; cleanup_directory::Bool = false)
    db_collect_temp(GamesOnNetworks.SETTINGS.database, directory_path, cleanup_directory=cleanup_directory)
    return nothing
end



# function db_insert_model_data(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_model_list::Vector{<:GraphModel}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition})
#     #add validation here??  
#     for game in game_list
#         for simparams in sim_params_list
#             for graphmodel in graph_model_list
#                 for startingcondition in starting_condition_list
#                     for stoppingcondition in stopping_condition_list
#                     db_insert_game(GamesOnNetworks.SETTINGS.database, game)
#                     db_insert_graph(GamesOnNetworks.SETTINGS.database, graphmodel)
#                     db_insert_sim_params(GamesOnNetworks.SETTINGS.database, simparams, GamesOnNetworks.SETTINGS.use_seed)
#                     db_insert_starting_condition(GamesOnNetworks.SETTINGS.database, startingcondition)
#                     db_insert_stopping_condition(GamesOnNetworks.SETTINGS.database, stoppingcondition)
#                     end
#                 end
#             end
#         end
#     end
# end



# #NOTE: FIX
# function db_restore_model(simulation_id::Integer) #MUST FIX TO USE UUID
#     simulation_df = execute_query_simulations_for_restore(GamesOnNetworks.SETTINGS.database, simulation_id)
#     agents_df = execute_query_agents_for_restore(GamesOnNetworks.SETTINGS.database, simulation_id)

#     #reproduce SimParams object
#     reproduced_sim_params = JSON3.read(simulation_df[1, :simparams], SimParams)

#     #reproduce Game object
#     payoff_matrix_size = JSON3.read(simulation_df[1, :payoff_matrix_size], Tuple)
#     payoff_matrix_length = payoff_matrix_size[1] * payoff_matrix_size[2]
#     reproduced_game = JSON3.read(simulation_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], payoff_matrix_length})

#     #reproduced Graph     ###!! dont need to reproduce graph unless the simulation is a pure continuation of 1 long simulation !!###
#     reproduced_graph_model = JSON3.read(simulation_df[1, :graphmodel], GraphModel)
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
#     return (game=reproduced_game, simparams=reproduced_sim_params, graphmodel=reproduced_graph_model, meta_graph=reproduced_meta_graph, use_seed=seed_bool, period=simulation_df[1, :period], group_id=simulation_df[1, :group_id])
# end

end #Database