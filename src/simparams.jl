#NOTE: should starting and stopping conditions be added into SimParams??

"""
    SimParams

Type to define and store simulation parameters.
"""
struct SimParams #NOTE: put periods_elapsed into SimParams (default 0) and allow user to define the matches_per_period (default 1?)
    number_agents::Int #switch to 'population'
    memory_length::Int
    error::Float64
    random_seed::Int #probably don't need a random seed in every SimParams struct?
    # matches_per_period::Function #allow users to define their own matches per period as a function of other parameters?

    function SimParams(number_agents::Int, memory_length::Int, error::Float64; random_seed::Union{Nothing, Int} = nothing)
        @assert number_agents >= 2 "'population' must be >= 2"
        @assert memory_length >= 1 "'memory_length' must be positive"
        @assert 0.0 <= error <= 1.0 "'error' must be between 0.0 and 1.0"
        if random_seed === nothing random_seed = 1234 end
        return new(number_agents, memory_length, error, random_seed)
    end
    function SimParams()
        return new()
    end
end


##########################################
# SimParams Accessors
##########################################

"""
    number_agents(simparams::SimParams)

Get the population size simulation parameter N.
"""
number_agents(simparams::SimParams) = getfield(simparams, :number_agents)

"""
    memory_length(simparams::SimParams)

Get the memory length simulation parameter m.
"""
memory_length(simparams::SimParams) = getfield(simparams, :memory_length)

"""
    error_rate(simparams::SimParams)

Get the error rate simulation parameter ϵ.
"""
error_rate(simparams::SimParams) = getfield(simparams, :error)

# """
#     matches_per_period(simparams::SimParams)

# Get the number of matches per period for the simulation.
# """
# matches_per_period(simparams::SimParams) = getfield(simparams, :matches_per_period)

"""
    random_seed(simparams::SimParams)

Get the random seed for the simulation.
"""
random_seed(simparams::SimParams) = getfield(simparams, :random_seed)

"""
    displayname(simparams::SimParams)

Get the string used for displaying a SimParams instance.
"""
displayname(simparams::SimParams) = "N=$(number_agents(simparams)) m=$(memory_length(simparams)) e=$(error_rate(simparams))"

Base.show(simparams::SimParams) = println(displayname(simparams))




##########################################
# SimParams Extra Constructors
##########################################

"""
    construct_simparams_list(;number_agents_list::Vector{<:Integer}, memory_length_list::Vector{<:Integer}, error_list::Vector{Float64}, tags::Union{Nothing, NamedTuple{(:tag1, :tag2, :tag1_proportion), Tuple{Symbol, Symbol, Float64}}} = nothing, random_seed::Union{Nothing, Int} = nothing)

Construct a list of SimParams instances with various parameter combinations.
"""
function construct_simparams_list(;number_agents_list::Vector{Int}, memory_length_list::Vector{Int}, error_list::Vector{Float64}, random_seed::Union{Nothing, Int} = nothing)
    simparams_list = Vector{SimParams}([])
    for number_agents in number_agents_list
        for memory_length in memory_length_list
            for error in error_list
                new_simparams_set = SimParams(number_agents, memory_length, error, random_seed=random_seed)
                push!(simparams_list, new_simparams_set)
            end
        end
    end
    return simparams_list
end