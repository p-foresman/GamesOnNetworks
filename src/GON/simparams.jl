const UserVariables = Dict{Symbol, Any}

"""
    SimParams

Type to define and store simulation parameters.
"""
struct SimParams #NOTE: allow user to define the matches_per_period (default 1?)
    number_agents::Int #switch to 'population'
    memory_length::Int
    error::Float64
    # matches_per_period::Function #allow users to define their own matches per period as a function of other parameters?
    starting_condition_fn_str::String
    stopping_condition_fn_str::String
    user_variables::UserVariables #NOTE: should starting_condition_variables and stopping_condition_variables be separated? (maybe not, it's on the user to manage these)
    # random_seed::Int #probably don't need a random seed in every SimParams struct?


    function SimParams(number_agents::Int, memory_length::Int, error::Float64, starting_condition_fn_str::String, stopping_condition_fn_str::String; user_variables::UserVariables=UserVariables())
        @assert number_agents >= 2 "'population' must be >= 2"
        @assert memory_length >= 1 "'memory_length' must be positive"
        @assert 0.0 <= error <= 1.0 "'error' must be between 0.0 and 1.0"
        @assert isdefined(Main, Symbol(starting_condition_fn_str)) "the starting_condition_fn_str provided does not correlate to a defined function"
        @assert isdefined(Main, Symbol(stopping_condition_fn_str)) "the stopping_condition_fn_str provided does not correlate to a defined function"
        return new(number_agents, memory_length, error, starting_condition_fn_str, stopping_condition_fn_str, user_variables)
    end
    function SimParams()
        return new()
    end
    function SimParams(number_agents::Int, memory_length::Int, error::Float64, starting_condition_fn_str::String, stopping_condition_fn_str::String, user_variables::UserVariables)
        @assert number_agents >= 2 "'population' must be >= 2"
        @assert memory_length >= 1 "'memory_length' must be positive"
        @assert 0.0 <= error <= 1.0 "'error' must be between 0.0 and 1.0"
        @assert isdefined(Main, Symbol(starting_condition_fn_str)) "the starting_condition_fn_str provided does not correlate to a defined function"
        @assert isdefined(Main, Symbol(stopping_condition_fn_str)) "the stopping_condition_fn_str provided does not correlate to a defined function"
        return new(number_agents, memory_length, error, starting_condition_fn_str, stopping_condition_fn_str, user_variables)
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

# """
#     random_seed(simparams::SimParams)

# Get the random seed for the simulation.
# """
# random_seed(simparams::SimParams) = getfield(simparams, :random_seed)




const _starting_condition_registry = Vector{Expr}()

"""
    @startingcondition fn

A macro used to register user starting conditions to be used in GamesOnNetworks. This MUST precede any starting conditions used in a user's simulations.
"""
macro startingcondition(fn)
    push!(_starting_condition_registry, fn)
    @everywhere eval($fn) #NOTE: could do GamesOnNetworks.eval() to evaluate it into the global scope of GamesOnNetworks instead of Main
    return nothing
end

"""
    starting_condition_fn_str(simparams::SimParams)

Get the 'starting_condition_fn_str' SimParams field.
"""
starting_condition_fn_str(simparams::SimParams) = getfield(simparams, :starting_condition_fn_str)

"""
    starting_condition_fn(simparams::SimParams)

Get the user-defined starting condition function which correlates to the String stored in the 'starting_condition_fn_str' SimParams field.
"""
starting_condition_fn(simparams::SimParams) = getfield(Main, Symbol(starting_condition_fn_str(simparams)))




const _stopping_condition_registry = Vector{Expr}()

"""
    @stoppingcondition fn

A macro used to register user stopping conditions to be used in GamesOnNetworks. This MUST precede any stopping conditions used in a user's simulations.
"""
macro stoppingcondition(fn)
    push!(_stopping_condition_registry, fn)
    @everywhere eval($fn) #NOTE: could do GamesOnNetworks.eval() to evaluate it into the global scope of GamesOnNetworks instead of Main
    return nothing
end

"""
    stopping_condition_fn_str(simparams::SimParams)

Get the 'stopping_condition_fn_str' SimParams field.
"""
stopping_condition_fn_str(simparams::SimParams) = getfield(simparams, :stopping_condition_fn_str)

"""
    stopping_condition_fn(simparams::SimParams)

Get the user-defined stopping condition function which correlates to the String stored in the 'stopping_condition_fn' SimParams field.
"""
stopping_condition_fn(simparams::SimParams) = getfield(Main, Symbol(stopping_condition_fn_str(simparams)))


function _assert_registries()
    @assert !isempty(_starting_condition_registry) "Must define at least one starting condition function with the @startingcondition macro"
    @assert !isempty(_stopping_condition_registry) "Must define at least one stopping condition function with the @stoppingcondition macro"
    return nothing
end


"""
    user_variables(simparams::SimParams)

Get the extra user-defined SimParam variables. Note: these should denote default values and should only be updated in State!
"""
user_variables(simparams::SimParams) = getfield(simparams, :user_variables)

# setfield!(::SimParams, :user_variables, ::Any) = raise Exception() #dont want user to be able to change this


"""
    displayname(simparams::SimParams)

Get the string used for displaying a SimParams instance.
"""
displayname(simparams::SimParams) = "N=$(number_agents(simparams)) m=$(memory_length(simparams)) e=$(error_rate(simparams)) starting=$(starting_condition_fn_str(simparams)) stopping=$(stopping_condition_fn_str(simparams))"

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