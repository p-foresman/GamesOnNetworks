"""
    DB(;kwargs...)

Create a connection to the configured database.
"""
DB(; kwargs...) = DB(GamesOnNetworks.MAIN_DB(); kwargs...)
DB(::Nothing; kwargs...) = _nodb()
"""
    sql(qp::QueryParams)

Generate a SQL query for a QueryParams instance (based on configured database type).
"""
sql(qp::QueryParams) = sql(GamesOnNetworks.DATABASE(), qp)
sql(::Nothing, ::QueryParams) = _nodb()
# function sql(qp::QueryParams)
#     if isempty(GamesOnNetworks.SETTINGS.query)
#         return sql(GamesOnNetworks.SETTINGS.database, qp)
#     else
#         return sql(GamesOnNetworks.SETTINGS.query, qp)
#     end
# end


"""
    db_execute(sql::SQL)

Execute SQL (String) on the configured database.
"""
db_execute(sql::SQL) = db_execute(GamesOnNetworks.MAIN_DB(), sql)
db_execute(::Nothing, ::SQL) = _nodb()

"""
    db_query(sql::SQL)

Query the configured database using the SQL (String) provided. Returns a DataFrame containing results.
"""
db_query(sql::SQL) = db_query(GamesOnNetworks.DATABASE(), sql)
db_query(::Nothing, ::SQL) = _nodb()
# function db_query(sql::SQL)
#     if isempty(GamesOnNetworks.SETTINGS.query)
#         return db_query(GamesOnNetworks.SETTINGS.database, sql)
#     else
#         return db_query(GamesOnNetworks.SETTINGS.query, sql)
#     end
# end


"""
    db_query(qp::QueryParams)

Query the configured database and attached databases using the QueryParams provided. Returns a DataFrame containing results.
"""
db_query(qp::QueryParams; kwargs...) = db_query(GamesOnNetworks.DATABASE(), qp; kwargs...)
db_query(::Nothing, ::QueryParams) = _nodb()

#db_query(qp::Query_simulations; ensure_samples::Bool=false) = db_query(GamesOnNetworks.DATABASE(), qp; ensure_samples=ensure_samples)

# db_begin_transaction() = db_begin_transaction(GamesOnNetworks.SETTINGS.database)
# db_close(db::SQLiteDB) = SQLite.close(db)
# db_commit_transaction(db::SQLiteDB) = SQLite.commit(db)

db_init() = db_init(GamesOnNetworks.MAIN_DB())
db_init(::Nothing) = _nodb()


db_insert_sim_group(description::String) = db_insert_sim_group(GamesOnNetworks.MAIN_DB(), description)
db_insert_sim_group(::Nothing, ::String) = _nodb()

db_insert_game(game::Game) = db_insert_game(GamesOnNetworks.MAIN_DB(), game)
db_insert_game(::Nothing, ::Game) = _nodb()

db_insert_graphmodel(graphmodel::GraphModel) = db_insert_graphmodel(GamesOnNetworks.MAIN_DB(), graphmodel)
db_insert_graphmodel(::Nothing, ::GraphModel) = _nodb()

db_insert_parameters(params::Parameters, use_seed::Bool) = db_insert_parameters(GamesOnNetworks.MAIN_DB(), params, use_seed)
db_insert_parameters(::Nothing, ::Parameters, ::Bool) = _nodb()


db_insert_model(model::Model; model_id::Union{Nothing, Integer}) = db_insert_model(GamesOnNetworks.MAIN_DB(), model, model_id=model_id)
db_insert_model(::Nothing, ::Model) = _nodb()

db_has_incomplete_simulations() = db_has_incomplete_simulations(GamesOnNetworks.MAIN_DB())
db_has_incomplete_simulations(::Nothing) = _nodb()

db_collect_temp(directory_path::String; cleanup_directory::Bool = false) = db_collect_temp(GamesOnNetworks.MAIN_DB(), directory_path, cleanup_directory=cleanup_directory)
db_collect_temp(::Nothing, ::String) = _nodb()