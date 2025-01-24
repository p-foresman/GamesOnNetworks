# Attempt to modularize all of the sql queryies using CTEs (Common Table Expressions)

abstract type QueryParams end

# These use a naming convention of Query_tablename so that the tablename is explicit and easily retrievable from the type name

struct Query_games <: QueryParams
    name::Vector{String}

    Query_games(name::Vector{String}) = new(name) #doesnt work
end
Query_games() = Query_games(Vector{String}())


struct Query_parameters <: QueryParams
    number_agents::Vector{Int}
    memory_length::Vector{Int}
    error::Vector{Float64}
    starting_condition::Vector{String}
    stopping_condition::Vector{String}
end
function Query_parameters(number_agents::Vector{<:Integer}=[],
    memory_length::Vector{<:Integer}=[],
    error::Vector{<:Real}=[],
    starting_condition::Vector{String}=[],
    stopping_condition::Vector{String}=[]
) 
    Query_parameters(number_agents, memory_length, error, starting_condition, stopping_condition)
end

abstract type Query_GraphModel <: QueryParams end
struct Query_CompleteModel <: Query_GraphModel end
struct Query_ErdosRenyiModel <: Query_GraphModel
    λ::Vector{Float64}
end
struct Query_SmallWorldModel <: Query_GraphModel
    λ::Vector{Float64}
    β::Vector{Float64}
end
struct Query_ScaleFreeModel <: Query_GraphModel
    λ::Vector{Float64}
    α::Vector{Float64}
end
struct Query_StochasticBlockModel <: Query_GraphModel
    λ::Vector{Float64}
    blocks::Vector{Int}
    p_in::Vector{Float64}
    p_out::Vector{Float64}
end
type(::T) where {T<:Query_GraphModel} = split(string(T), "_")[2]

struct Query_graphmodels <: QueryParams
    graphmodels::Vector{<:Query_GraphModel}
end


# struct Query_graphmodels <: QueryParams #NOTE: need an extra specifier for CompleteModel!
#     λ::Vector{Float64} #this OR this AND others
#     β::Vector{Float64}
#     α::Vector{Float64}
#     blocks::Vector{Int}
#     p_in::Vector{Float64}
#     p_out::Vector{Float64}
# end
# function Query_graphmodels(λ::Vector{<:Real}=[],
#     β::Vector{<:Real}=[],
#     α::Vector{<:Real}=[],
#     blocks::Vector{<:Integer}=[],
#     p_in::Vector{<:Real}=[],
#     p_out::Vector{<:Real}=[]
# ) 
#     Query_graphmodels(λ, β, α, blocks, p_in, p_out)
# end

struct Query_models <: QueryParams
    games::Query_games
    parameters::Query_parameters
    graphmodels::Query_graphmodels
end

struct Query_simulations <: QueryParams #NOTE: this might be overly complicated
    model::Query_models
    complete::Union{Bool, Nothing}
    sample_size::Int

    function Query_simulations(games::Query_games, parameters::Query_parameters, graphmodels::Query_graphmodels; complete::Union{Bool, Nothing}=nothing, sample_size::Integer=0)
        @assert sample_size >= 0 "sample_size must positive (0 for all samples)"
        return new(Query_models(games, parameters, graphmodels), complete, sample_size)
    end
end


table(::T) where {T<:QueryParams} = split(string(T), "_")[2]


# function sql(qp::Query_models)
#     "WITH CTE_games AS ($(sql(qp.game))), CTE_parameters AS ($(sql(qp.parameters))), CTE_graphmodels AS ($(sql(qp.graphmodel))) SELECT *, model_id FROM CTE_games, CTE_parameters, CTE_graphmodels INNER JOIN models"
# end



