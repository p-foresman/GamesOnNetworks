"""
    sql(::SQLiteInfo, qp::QueryParams)

Generate a SQL query for a QueryParams instance (based on SQLite).
"""

function sql(db_info::SQLiteInfo, qp::QueryParams) #for games, parameters, and graphmodels
    filter_str = sql_filter(db_info, qp)
    if !isempty(filter_str)
        filter_str = " WHERE " * filter_str
    end
    return "SELECT * FROM $(table(qp))$filter_str"
end

function sql(db_info::Vector{SQLiteInfo}, qp::QueryParams) #for games, parameters, and graphmodels
    @assert !isempty(db_info) "db_info Vector is empty"                                                           
    filter_str = sql_filter(db_info[1], qp) #doesnt matter which db is passed, just used for multiple dispatch
    if !isempty(filter_str)
        filter_str = " WHERE " * filter_str
    end
    union_str = ""
    for db in db_info[2:end]
        union_str *= " UNION ALL SELECT * FROM $(db.name).$(table(qp))$filter_str"
    end
    return "SELECT DISTINCT * FROM (SELECT * FROM $(table(qp))$filter_str$union_str)" #removes duplicates when querying multiple databases
end

#NOTE: fix to be like models
function sql(db_info::DatabaseSettings{SQLiteInfo}, qp::QueryParams) #for games, parameters, and graphmodels
    filter_str = sql_filter(main(db_info), qp) #doesnt matter which db is passed, just used for multiple dispatch
    if !isempty(filter_str)
        filter_str = " WHERE " * filter_str
    end
    union_str = ""
    for db in attached(db_info)
        union_str *= " UNION ALL SELECT * FROM $(db.name).$(table(qp))$filter_str"
    end
    return "SELECT DISTINCT * FROM (SELECT * FROM $(table(qp))$filter_str$union_str)" #removes duplicates when querying multiple databases
end

function sql_filter(::SQLiteInfo, qp::Query_games)
    filter_str = ""
    if length(qp.name) == 1
        filter_str = "($(table(qp)).name = '$(qp.name[1])')"
    elseif !isempty(qp.name)
        filter_str = "($(table(qp)).name IN $(Tuple(qp.name)))"
    end
    return filter_str
end


function sql_filter(::SQLiteInfo, qp::Query_parameters)
    filter_str = ""
    for field in fieldnames(typeof(qp))
        vals = getfield(qp, field)
        if isempty(vals)
            continue
        elseif length(vals) == 1
            filter_str *= "$(table(qp)).$(string(field)) = '$(vals[1])' AND "
        else
            filter_str *= "$(table(qp)).$(string(field)) IN $(Tuple(vals)) AND "
        end
    end
    if !isempty(filter_str)
        filter_str = "(" * chop(filter_str, tail=5) * ")"
    end
    return filter_str
end

function sql_filter(::SQLiteInfo, qp::Query_GraphModel)
    filter_str = "$(table(qp)).type = '$(type(qp))' AND "
    for field in fieldnames(typeof(qp))
        vals = getfield(qp, field)
        if isempty(vals)
            continue
        elseif length(vals) == 1
            filter_str *= "$(table(qp)).$(string(field)) = '$(vals[1])' AND "
        else
            filter_str *= "$(table(qp)).$(string(field)) IN $(Tuple(vals)) AND "
        end
    end
    if !isempty(filter_str)
        filter_str = "(" * chop(filter_str, tail=5) * ")"
    end
    return filter_str
end

function sql_filter(db_info::SQLiteInfo, qp::Query_graphmodels)
    filter_str = ""
    for graphmodel in qp.graphmodels
        temp_str = sql_filter(db_info, graphmodel)
        if !isempty(temp_str)
            temp_str *= " OR "
        end
        filter_str *= temp_str
    end
    return "(" * chop(filter_str, tail=4) * ")"
end


# function sql_filter(::SQLiteInfo, qp::Query_graphmodels)
#     filter_str = ""
#     for graphmodel in qp.graphmodels
#         temp_str = "$(table(qp)).type = '$(type(graphmodel))' AND "
#         for field in fieldnames(typeof(graphmodel))
#             vals = getfield(graphmodel, field)
#             if isempty(vals)
#                 continue
#             elseif length(vals) == 1
#                 temp_str *= "$(table(qp)).$(string(field)) = '$(vals[1])' AND "
#             else
#                 temp_str *= "$(table(qp)).$(string(field)) IN $(Tuple(vals)) AND "
#             end
#         end
#         if !isempty(temp_str)
#             temp_str = "(" * chop(temp_str, tail=5) * ") OR "
#         end
#         filter_str *= temp_str
#     end
#     return chop(filter_str, tail=4)
# end


function sql_filter(db_info::SQLiteInfo, qp::Query_models) #NOTE: refactor
    filter_str = ""
    games_filter_str = sql_filter(db_info, qp.games)
    if !isempty(games_filter_str)
        games_filter_str *= " AND "
    end
    filter_str *= games_filter_str
    parameters_filter_str = sql_filter(db_info, qp.parameters)
    if !isempty(parameters_filter_str)
        parameters_filter_str *= " AND "
    end
    filter_str *= parameters_filter_str
    graphmodels_filter_str = sql_filter(db_info, qp.graphmodels)
    if !isempty(graphmodels_filter_str)
        graphmodels_filter_str *= " AND "
    end
    filter_str *= graphmodels_filter_str
    if !isempty(filter_str)
        filter_str = "WHERE " * chop(filter_str, tail=5)
    end
    return filter_str
end

function sql(::SQLiteInfo, ::Query_models, filter_str::String, db_name::String)
    """
    SELECT
        models.id as model_id,
        models.game_id,
        models.parameters_id,
        models.graphmodel_id,
        games.name,
        games.game,
        parameters.number_agents,
        parameters.memory_length,
        parameters.error,
        parameters.starting_condition,
        parameters.stopping_condition,
        parameters.parameters,
        graphmodels.type as graphmodel_type,
        graphmodels.display as graphmodel_display,
        graphmodels.graphmodel,
        graphmodels.λ,
        graphmodels.β,
        graphmodels.α,
        graphmodels.blocks,
        graphmodels.p_in,
        graphmodels.p_out,
        '$db_name' as db_name
    FROM $db_name.models
    INNER JOIN $db_name.parameters ON $db_name.models.parameters_id = $db_name.parameters.id
    INNER JOIN $db_name.games ON $db_name.models.game_id = $db_name.games.id
    INNER JOIN $db_name.graphmodels ON $db_name.models.graphmodel_id = $db_name.graphmodels.id
    $filter_str
    """
end

# sql(db_info::SQLiteInfo, qp::Query_models) = sql(db_info, qp, sql_filter(db_info, qp))

sql(db_info::SQLiteInfo, qp::Query_models) = sql(db_info, qp, sql_filter(db_info, qp), "main")

function sql(db_info::Vector{SQLiteInfo}, qp::Query_models)
    @assert !isempty(db_info) "db_info Vector is empty"                                                           
    filter_str = sql_filter(db_info[1], qp)
    union_str = ""
    for db in db_info[2:end]
        union_str *= " UNION ALL " * sql(db, qp, filter_str, db.name)
    end
    # distinct = "model_id, game_id, parameters_id, graphmodel_id, game, parameters, graphmodel"
    # println("SELECT DISTINCT * FROM (" * sql(db_info[1], qp, filter_str, "main") * union_str * ")")
    return "SELECT DISTINCT * FROM (" * sql(db_info[1], qp, filter_str, "main") * union_str * ")"
end

function sql(db_info::DatabaseSettings{SQLiteInfo}, qp::Query_models)
    filter_str = sql_filter(main(db_info), qp)
    union_str = ""
    for db in attached(db_info)
        union_str *= " UNION ALL " * sql(db, qp, filter_str, db.name)
    end
    # return "SELECT DISTINCT * FROM (" * sql(main(db_info), qp, filter_str, "main") * union_str * ")" #NOTE: this causes massive slowdown with big datasets, hopefully it's not needed
    return sql(main(db_info), qp, filter_str, "main") * union_str #* ")" #"SELECT DISTINCT * FROM (" * 
end


function sql(::SQLiteInfo, qp::Query_simulations, db_name::String) #NOTE: default db_name is main, but this could cause issues if used incorrectly
    # WITH CTE_models AS (
    #     $(sql(db_info, qp.model, db_name))
    # )

    #, CTE_models.db_name
    """
    SELECT * FROM (
        SELECT
            ROW_NUMBER() OVER ( 
                    PARTITION BY CTE_models.model_id, CTE_models.db_name
                    ORDER BY $(!iszero(qp.sample_size) ? "RANDOM()" : "(SELECT NULL)")
            ) RowNum,
            CTE_models.model_id,
            CTE_models.game_id,
            CTE_models.parameters_id,
            CTE_models.graphmodel_id,
            CTE_models.number_agents,
            CTE_models.memory_length,
            CTE_models.error,
            CTE_models.starting_condition,
            CTE_models.stopping_condition,
            CTE_models.graphmodel_type,
            CTE_models.graphmodel_display,
            CTE_models.λ,
            CTE_models.β,
            CTE_models.α,
            CTE_models.blocks,
            CTE_models.p_in,
            CTE_models.p_out,
            CTE_models.db_name,
            simulations.uuid as simulation_uuid,
            simulations.period,
            simulations.complete
        FROM $db_name.simulations
        INNER JOIN CTE_models ON $db_name.simulations.model_id = CTE_models.model_id
        WHERE CTE_models.db_name = '$db_name'
        $(!isnothing(qp.complete) ? "AND complete = $(Int(qp.complete))" : "")
    )
    $(!iszero(qp.sample_size) ? "WHERE RowNum <= $(qp.sample_size)" : "")
    """
end
#NOTE: need to union all in the simulations sql, otherwise different models with the same id will cause issues!

function sql(db_info::SQLiteInfo, qp::Query_simulations)
    cte_models_str = "WITH CTE_models AS (" * sql(db_info, qp.model) * ") "                                  
    return cte_models_str * sql(db_info, qp, "main")
end

function sql(db_info::Vector{SQLiteInfo}, qp::Query_simulations)
    @assert !isempty(db_info) "db_info Vector is empty"
    cte_models_str = "WITH CTE_models AS (" * sql(db_info, qp.model) * ") "                                  
    union_str = ""
    for db in db_info[2:end]
        union_str *= " UNION ALL " * sql(db, qp, db.name)
    end
    # println(cte_models_str * sql(db_info[1], qp) * union_str)
    return cte_models_str * sql(db_info[1], qp) * union_str
end

function sql(db_info::DatabaseSettings{SQLiteInfo}, qp::Query_simulations)
    # @assert !isempty(db_info) "db_info Vector is empty"
    cte_models_str = "WITH CTE_models AS (" * sql(db_info, qp.model) * ") "                                  
    union_str = ""
    for db in attached(db_info)
        union_str *= " UNION ALL " * sql(db, qp, db.name)
    end
    return cte_models_str * sql(main(db_info), qp, "main") * union_str
end