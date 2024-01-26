struct SimParams
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
        matches_per_period = floor(number_agents / 2)
        # sufficient_equity = (1 - error) * memory_length
        return new(number_agents, memory_length, error, matches_per_period, tags, random_seed)
    end
    function SimParams()
        return new()
    end
end

displayName(sim_params::SimParams) = "N=$(sim_params.number_agents) m=$(sim_params.memory_length) e=$(sim_params.error)"


############### parameter initialization (for simulateIterator()) ############### NOTE:ADD MORE
function constructSimParamsList(;number_agents_list::Vector{<:Integer}, memory_length_list::Vector{<:Integer}, error_list::Vector{Float64}, tags::Union{Nothing, NamedTuple{(:tag1, :tag2, :tag1_proportion), Tuple{Symbol, Symbol, Float64}}} = nothing, random_seed::Union{Nothing, Int} = nothing)
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