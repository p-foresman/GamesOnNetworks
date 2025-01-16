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
        sz = sum(GamesOnNetworks.volume(populations, memory_lengths, error_rates, starting_conditions, stopping_conditions) .* size.(graphmodels))
        return new(game, populations, memory_lengths, error_rates, starting_conditions, stopping_conditions, graphmodels, sz)
    end
end

Base.size(generator::ModelGenerator) = getfield(generator, :size)


function generate_model(generator::ModelGenerator, index::Integer; use_seed::Bool=false) #NOTE: could use iterator method here too, but would be much less efficient
    count = 0
    for population in generator.populations
        for memory_length in generator.memory_lengths
            for error_rate in generator.error_rates
                for starting_condition in generator.starting_conditions
                    for stopping_condition in generator.stopping_conditions
                        params = Parameters(population, memory_length, error_rate, starting_condition[1], stopping_condition[1], user_variables=merge(starting_condition[2], stopping_condition[2]))
                        for graphmodel_generator in generator.graphmodels
                            for graphmodel in graphmodel_generator
                                count += 1
                                if count == index
                                    Random.seed!(count)
                                    return Model(generator.game, params, graphmodel)
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

function generate_database(generator::ModelGenerator)
    count = 0
    for population in generator.populations
        for memory_length in generator.memory_lengths
            for error_rate in generator.error_rates
                for starting_condition in generator.starting_conditions
                    for stopping_condition in generator.stopping_conditions
                        params = Parameters(population, memory_length, error_rate, starting_condition[1], stopping_condition[1], user_variables=merge(starting_condition[2], stopping_condition[2]))
                        for graphmodel_generator in generator.graphmodels
                            for graphmodel in graphmodel_generator
                                Random.seed!(count)
                                Database.db_insert_model(Model(generator.game, params, graphmodel))
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