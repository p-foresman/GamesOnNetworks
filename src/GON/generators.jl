
volume(vec::Vector...) = prod([length(v) for v in vec]) #helper function

abstract type GraphModelGenerator end


#NOTE: could somehow generate these out of the actual graphmodels (they have pretty much the same fields, theres got to be a way)

struct ErdosRenyiModelGenerator <: GraphModelGenerator
    λ::Vector{Float64}
    size::Int

    ErdosRenyiModelGenerator(λ::Vector{<:Real}) = new(λ, length(λ)) #NOTE: not yet using λ in these, so size is just 1 here
end

struct SmallWorldModelGenerator <: GraphModelGenerator
    λ::Vector{Float64}
    β::Vector{Float64}
    size::Int

    SmallWorldModelGenerator(λ::Vector{<:Real}, β::Vector{Float64}) = new(λ, β, volume(λ, β))
end

struct ScaleFreeModelGenerator <: GraphModelGenerator
    λ::Vector{Float64}
    α::Vector{Float64}
    size::Int

    ScaleFreeModelGenerator(λ::Vector{<:Real}, α::Vector{Float64}) = new(λ, α, volume(λ, α))
end

struct StochasticBlockModelGenerator <: GraphModelGenerator
    λ::Vector{Float64}
    blocks::Vector{Int}
    p_in::Vector{Float64}
    p_out::Vector{Float64}
    size::Int

    StochasticBlockModelGenerator(λ::Vector{<:Real}, blocks::Vector{Int}, p_in::Vector{Float64}, p_out::Vector{Float64}) = new(λ, blocks, p_in, p_out, volume(λ, blocks, p_in, p_out))
end

Base.size(graphmodel_generator::GraphModelGenerator) = getfield(graphmodel_generator, :size)

get_params(vec::Vector...; index::Integer) = first(Iterators.drop(Iterators.product(vec...), index - 1))

generate_model(graphmodel_generator::ErdosRenyiModelGenerator, index::Integer) = ErdosRenyiModel(graphmodel_generator.λ[index])
generate_model(graphmodel_generator::SmallWorldModelGenerator, index::Integer) = SmallWorldModel(get_params(graphmodel_generator.λ, graphmodel_generator.β; index=index)...)
generate_model(graphmodel_generator::ScaleFreeModelGenerator, index::Integer) = ScaleFreeModel(get_params(graphmodel_generator.λ, graphmodel_generator.α; index=index)...)
generate_model(graphmodel_generator::StochasticBlockModelGenerator, index::Integer) = StochasticBlockModel(get_params(graphmodel_generator.λ, graphmodel_generator.blocks, graphmodel_generator.p_in, graphmodel_generator.p_out; index=index)...)

function Base.iterate(graphmodel_generator::GraphModelGenerator, state=1)
    if state > graphmodel_generator.size
        return nothing
    else
        return (generate_model(graphmodel_generator, state), state + 1)
    end    
end




"""
    ModelGenerator

A type to store the values for a parameter sweep. Can be used to populate a database with model data and to generate a model given a model id.
"""
struct ModelGenerator
    game::Game
    populations::Vector{Int}
    memory_lengths::Vector{Int}
    error_rates::Vector{Float64}
    starting_conditions::Vector{Tuple{String, UserVariables}} # ("starting_condition_name", UserVariables(var1=>'val1', var2=>'val2'))
    stopping_conditions::Vector{Tuple{String, UserVariables}} # ("stopping_condition_name", UserVariables(var1=>'val1', var2=>'val2'))
    graphmodels::Vector{GraphModelGenerator}
    size::Int

    function ModelGenerator(
        game::Game,
        populations::Vector{Int},
        memory_lengths::Vector{Int},
        error_rates::Vector{Float64},
        starting_conditions::Vector{Tuple{String, UserVariables}},
        stopping_conditions::Vector{Tuple{String, UserVariables}},
        graphmodels::Vector{GraphModelGenerator}
        )
        sz = sum(volume(populations, memory_lengths, error_rates, starting_conditions, stopping_conditions) .* size.(graphmodels))
        return new(game, populations, memory_lengths, error_rates, starting_conditions, stopping_conditions, graphmodels, sz)
    end
end

Base.size(generator::ModelGenerator) = getfield(generator, :size)


function generate_model(generator::ModelGenerator, model_id::Integer) #NOTE: could use iterator method here too, but would be much less efficient
    count = 0
    for population in generator.populations
        for memory_length in generator.memory_lengths
            for error_rate in generator.error_rates
                for starting_condition in generator.starting_conditions
                    for stopping_condition in generator.stopping_conditions
                        simparams = SimParams(population, memory_length, error_rate, starting_condition[1], stopping_condition[1], user_variables=merge(starting_condition[2], stopping_condition[2]))
                        for graphmodel_generator in generator.graphmodels
                            for graphmodel in graphmodel_generator
                                count += 1
                                if count == model_id
                                    Random.seed!(count)
                                    return SimModel(generator.game, simparams, graphmodel)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nothing
end



"""
    get_model_id(process_num, num_processes_in_job)

Used in high-throughput computing jobs
"""
function get_model_id(process_num, num_processes_in_job) #NOTE: remove?
    return (process_num % num_processes_in_job) + 1
end