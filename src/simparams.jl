"""
    SimParams

Type to define and store simulation parameters.
"""
struct SimParams #NOTE: put periods_elapsed into SimParams (default 0) and allow user to define the matches_per_period (default 1?)
    number_agents::Int
    memory_length::Int
    error::Float64
    matches_per_period::Int
    tags::Union{Nothing, Tuple{Symbol, Symbol, Float64}}
    # tag1::Symbol #could make tags a vararg to have any given number of tags #NOTE: REMOVE
    # tag2::Symbol #NOTE: REMOVE
    # tag1_proportion::Float64 #NOTE: REMOVE
    random_seed::Int #probably don't need a random seed in every SimParams struct

    #all keyword arguments
    # function SimParams(number_agents::Int, memory_length::Int, error::Float64; tag1::Symbol, tag2::Symbol, tag1_proportion::Float64, random_seed::Int)
    #     matches_per_period = floor(number_agents / 2)
    #     # sufficient_equity = (1 - error) * memory_length
    #     return new(number_agents, memory_length, error, matches_per_period, tag1, tag2, tag1_proportion, random_seed)
    # end
    function SimParams(number_agents::Int, memory_length::Int, error::Float64; tags::Union{Nothing, NamedTuple{(:tag1, :tag2, :tag1_proportion), Tuple{Symbol, Symbol, Float64}}} = nothing, random_seed::Union{Nothing, Int} = nothing)
        if random_seed === nothing random_seed = 1234 end
        matches_per_period = floor(number_agents / 2) #NOTE: hard-coded for now
        # sufficient_equity = (1 - error) * memory_length
        return new(number_agents, memory_length, error, matches_per_period, tags, random_seed)
    end
    function SimParams()
        return new()
    end
end


##########################################
# SimParams Accessors
##########################################

"""
    number_agents(sim_params::SimParams)

Get the population size simulation parameter N.
"""
number_agents(sim_params::SimParams) = getfield(sim_params, :number_agents)

"""
    memory_length(sim_params::SimParams)

Get the memory length simulation parameter m.
"""
memory_length(sim_params::SimParams) = getfield(sim_params, :memory_length)

"""
    error_rate(sim_params::SimParams)

Get the error rate simulation parameter ϵ.
"""
error_rate(sim_params::SimParams) = getfield(sim_params, :error)

"""
    matches_per_period(sim_params::SimParams)

Get the number of matches per period for the simulation.
"""
matches_per_period(sim_params::SimParams) = getfield(sim_params, :matches_per_period)

"""
    random_seed(sim_params::SimParams)

Get the random seed for the simulation.
"""
random_seed(sim_params::SimParams) = getfield(sim_params, :random_seed)

"""
    displayname(sim_params::SimParams)

Get the string used for displaying a SimParams instance.
"""
displayname(sim_params::SimParams) = "N=$(number_agents(sim_params)) m=$(memory_length(sim_params)) e=$(error_rate(sim_params))"

Base.show(sim_params::SimParams) = println(displayname(sim_params))




##########################################
# SimParams Extra Constructors
##########################################

"""
    construct_sim_params_list(;number_agents_list::Vector{<:Integer}, memory_length_list::Vector{<:Integer}, error_list::Vector{Float64}, tags::Union{Nothing, NamedTuple{(:tag1, :tag2, :tag1_proportion), Tuple{Symbol, Symbol, Float64}}} = nothing, random_seed::Union{Nothing, Int} = nothing)

Construct a list of SimParams instances with various parameter combinations.
"""
function construct_sim_params_list(;number_agents_list::Vector{<:Integer}, memory_length_list::Vector{<:Integer}, error_list::Vector{Float64}, tags::Union{Nothing, NamedTuple{(:tag1, :tag2, :tag1_proportion), Tuple{Symbol, Symbol, Float64}}} = nothing, random_seed::Union{Nothing, Int} = nothing)
    sim_params_list = Vector{SimParams}([])
    for number_agents in number_agents_list
        for memory_length in memory_length_list
            for error in error_list
                new_sim_params_set = SimParams(number_agents, memory_length, error, tags=tags, random_seed=random_seed)
                push!(sim_params_list, new_sim_params_set)
            end
        end
    end
    return sim_params_list
end