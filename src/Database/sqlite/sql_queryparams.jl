"""
    sql(::SQLiteInfo, qp::QueryParams)

Generate a SQL query for a QueryParams instance (based on SQLite).
"""
# function sql(::SQLiteInfo, qp::QueryParams) #NOTE: once postgres is implemented, will need db_info to discern
#     where_str = ""
#     for field in fieldnames(typeof(qp))
#         vals = getfield(qp, field)
#         if isempty(vals)
#             continue
#         elseif length(vals) == 1
#             where_str *= "$(table(qp)).$(string(field)) = '$(vals[1])' AND "
#         else
#             where_str *= "$(table(qp)).$(string(field)) IN $(Tuple(vals)) AND "
#         end
#     end
#     if !isempty(where_str)
#         where_str = " WHERE " * chop(where_str, tail=5)
#     end
#     return "SELECT * FROM $(table(qp))$where_str"
# end

function sql(db_info::SQLiteInfo, qp::QueryParams) #for games, parameters, and graphmodels
    filter_str = sql_filter(db_info, qp)
    if !isempty(filter_str)
        filter_str = " WHERE " * filter_str
    end
    return "SELECT * FROM $(table(qp))$filter_str"
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

function sql(db_info::SQLiteInfo, qp::Query_models)
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
        graphmodels.p_out
    FROM models
    INNER JOIN parameters ON models.parameters_id = parameters.id
    INNER JOIN games ON models.game_id = games.id
    INNER JOIN graphmodels ON models.graphmodel_id = graphmodels.id
    $(sql_filter(db_info, qp))
    """
end


function sql(::SQLiteInfo, qp::Query_simulations)
    """
    WITH CTE_models AS (
            $(sql(qp.model))
        )
    SELECT * FROM (
        SELECT
            ROW_NUMBER() OVER ( 
                    PARTITION BY CTE_models.model_id
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
            simulations.uuid as simulation_uuid,
            simulations.period,
            simulations.complete
        FROM simulations
        INNER JOIN CTE_models ON simulations.model_id = CTE_models.model_id
        $(!isnothing(qp.complete) ? "WHERE complete = $(Int(qp.complete))" : "")
    )
    $(!iszero(qp.sample_size) ? "WHERE RowNum <= $(qp.sample_size)" : "");
    """
end


# OLD
# function sql(::SQLiteInfo, qp::Query_models)
#     """
#     WITH CTE_games AS (
#             $(sql(qp.game))
#         ),
#         CTE_parameters AS (
#             $(sql(qp.parameters))
#         ),
#         CTE_graphmodels AS (
#             $(sql(qp.graphmodel))
#         )
#     SELECT
#         models.id as model_id,
#         models.game_id,
#         models.parameters_id,
#         models.graphmodel_id,
#         CTE_games.name,
#         CTE_games.game,
#         CTE_parameters.number_agents,
#         CTE_parameters.memory_length,
#         CTE_parameters.error,
#         CTE_parameters.starting_condition,
#         CTE_parameters.stopping_condition,
#         CTE_parameters.parameters,
#         CTE_graphmodels.type,
#         CTE_graphmodels.graphmodel,
#         CTE_graphmodels.λ,
#         CTE_graphmodels.β,
#         CTE_graphmodels.α,
#         CTE_graphmodels.blocks,
#         CTE_graphmodels.p_in,
#         CTE_graphmodels.p_out
#     FROM models
#     INNER JOIN CTE_parameters ON models.parameters_id = CTE_parameters.id
#     INNER JOIN CTE_games ON models.game_id = CTE_games.id
#     INNER JOIN CTE_graphmodels ON models.graphmodel_id = CTE_graphmodels.id
#     WHERE 
#     """
# end


# function sql(::SQLiteInfo, qp::Query_simulations)
#     """
#     WITH CTE_models AS (
#             $(sql(qp.model))
#         )
#     SELECT * FROM (
#         SELECT
#             ROW_NUMBER() OVER ( 
#                     PARTITION BY CTE_models.model_id
#                     ORDER BY $(!iszero(qp.sample_size) ? "RANDOM()" : "(SELECT NULL)")
#             ) RowNum,
#             CTE_models.model_id,
#             CTE_models.game_id,
#             CTE_models.parameters_id,
#             CTE_models.graphmodel_id,
#             simulations.uuid as simulation_uuid,
#             simulations.period,
#             simulations.complete
#         FROM simulations
#         INNER JOIN CTE_models ON simulations.model_id = CTE_models.model_id
#         $(!isnothing(qp.complete) ? "WHERE complete = $(Int(qp.complete))" : "")
#     )
#     $(!iszero(qp.sample_size) ? "WHERE RowNum <= $(qp.sample_size)" : "");
#     """
# end