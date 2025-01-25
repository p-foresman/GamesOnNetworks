module Database

import
    ..GamesOnNetworks.SETTINGS, #get rid of this and change from SETTINGS -> GamesOnNetworks.SETTINGS to be explicit
    ..GraphsExt

using
    ..GamesOnNetworks,
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

DatabaseIdTuple = NamedTuple{(:game_id, :graph_id, :parameters_id, :starting_condition_id, :stopping_condition_id), NTuple{5, Int}}

#include QueryParams types for SQL query generation
include("queryparams.jl")

# include sqlite and postgresql specific APIs
include("./sqlite/database_api.jl")
include("./sqlite/sql_queryparams.jl") #NOTE: this ALL needs to be reorganized
# include("./postgres/database_api.jl")

# function barriers to interface with sqlite/postgres-specific functions using configured database in environment variable 'GamesOnNetworks.SETTINGS'

"""
    DB(;kwargs...)

Create a connection to the configured database.
"""
DB(;kwargs...) = DB(SETTINGS.database, kwargs...)

"""
    sql(qp::QueryParams)

Generate a SQL query for a QueryParams instance (based on configured database type).
"""
sql(qp::QueryParams) = sql(GamesOnNetworks.SETTINGS.database, qp)


"""
    db_execute(sql::SQL)

Execute SQL (String) on the configured database.
"""
db_execute(sql::SQL) = db_execute(GamesOnNetworks.SETTINGS.database, sql)


"""
    db_query(sql::SQL)

Query the configured database using the SQL (String) provided. Returns a DataFrame containing results.
"""
db_query(sql::SQL) = db_query(GamesOnNetworks.SETTINGS.database, sql)

"""
    db_query(qp::QueryParams)

Query the configured database using the QueryParams provided. Returns a DataFrame containing results.
"""
db_query(qp::QueryParams) = db_query(sql(qp))

db_query(qp::Query_simulations; ensure_samples::Bool=true) = db_query(GamesOnNetworks.SETTINGS.database, qp, ensure_samples=ensure_samples)

# db_begin_transaction() = db_begin_transaction(GamesOnNetworks.SETTINGS.database)
# db_close(db::SQLiteDB) = SQLite.close(db)
# db_commit_transaction(db::SQLiteDB) = SQLite.commit(db)

db_init() = db_init(GamesOnNetworks.SETTINGS.database)
db_init(::Nothing) = nothing


db_insert_sim_group(description::String) = db_insert_sim_group(GamesOnNetworks.SETTINGS.database, description)
db_insert_sim_group(::Nothing, ::String) = nothing

db_insert_game(game::Game) = db_insert_game(GamesOnNetworks.SETTINGS.database, game)
db_insert_game(::Nothing, ::Game) = nothing

db_insert_graphmodel(graphmodel::GraphModel) = db_insert_graphmodel(GamesOnNetworks.SETTINGS.database, graphmodel)
db_insert_graphmodel(::Nothing, ::GraphModel) = nothing

db_insert_parameters(params::Parameters, use_seed::Bool) = db_insert_parameters(GamesOnNetworks.SETTINGS.database, params, use_seed)
db_insert_parameters(::Nothing, ::Parameters, ::Bool) = nothing


function db_insert_model(model::Model; model_id::Union{Nothing, Integer}=nothing) #NOTE: use_seed needs to be more thought out here. Should it even be included in a model? (probably not, but in a simulation, YES!)
    return db_insert_model(GamesOnNetworks.SETTINGS.database, model, model_id=model_id)
end

function db_has_incomplete_simulations()
    return db_has_incomplete_simulations(GamesOnNetworks.SETTINGS.database)
end

function db_collect_temp(directory_path::String; cleanup_directory::Bool = false)
    db_collect_temp(GamesOnNetworks.SETTINGS.database, directory_path, cleanup_directory=cleanup_directory)
    return nothing
end

function _ensure_samples(df::DataFrame, qp::Query_simulations)
    #check to ensure all samples are present
    model_counts_df = combine(groupby(df, :model_id), nrow=>:count)
    insufficient_samples_str = ""
    for row in eachrow(model_counts_df)
        if row[:count] < qp.sample_size
            insufficient_samples_str *= "only $(row[:count]) samples for model $(row[:model_id])\n"
        end
    end
    !isempty(insufficient_samples_str) && throw(ErrorException("Insufficient samples for the following:\n" * insufficient_samples_str))

    #if a model has 0 samples, it won't show up in dataframe (it wasn't simulated)
    if nrow(model_counts_df) < Database.size(qp)
        throw(ErrorException("At least one model selected has no simulations"))
    end
    return nothing
end

end #Database