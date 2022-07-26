

#constructor for individual agents with relevant fields (mutable to update object later)
mutable struct Agent
    name::AbstractString
    tag::Symbol
    wealth::Int #is this necessary?
    memory::Vector{Tuple{Symbol, Int}}

    function Agent(name::AbstractString, tag::Symbol)
        return new(name, tag, 0, Vector{Int}([]))
    end
    function Agent()
        return new("", Symbol(), 0, Vector{Int}([]))
    end
end

#constructor for specific game to be played (mutable to update object later)
mutable struct Game
    name::AbstractString
    payoff_matrix::Matrix{Tuple{Int64, Int64}}
    strategies::Vector{Int64}
    player1::Agent
    player2::Agent

    function Game(name::AbstractString, payoff_matrix::Matrix{Tuple{Int64, Int64}}, strategies::Vector{Int64})
        new(name, payoff_matrix, strategies, Agent(), Agent())
    end
end

mutable struct SimParams
    number_agents::Int16 #will be initialized at 0 and updated based on number_agents_iterator value
    number_agents_iterator::StepRange
    memory_length::Int16 #will be initialized at 0 and updated based on memory_length_iterator value
    memory_length_iterator::StepRange
    memory_init_state::Symbol
    error::Float64 #will be initialized at 0.0 and updated based on error_list value (list iterated over)
    error_list::Vector{Float64}
    matches_per_period::Int32 #will be initialized at 0 and updated based on floor(number_agents/2) value in simulation
    sufficient_equity::Float64 #will be initialized at 0.0 and updated based on (1-error)*memory_length value in simulation
    tag1::Symbol #could make tags a vararg to have any given number of tags
    tag2::Symbol
    tag1_proportion::Float64
    averager::Int16
    random_seed::Int16

    #all keyword arguments
    function SimParams(;number_agents_start, number_agents_end, number_agents_step, memory_length_start, memory_length_end, memory_length_step, memory_init_state::Symbol, error_list::Vector{Float64}, tag1::Symbol, tag2::Symbol, tag1_proportion::Float64, averager, random_seed)
        number_agents_iterator = number_agents_start:number_agents_step:number_agents_end
        memory_length_iterator = memory_length_start:memory_length_step:memory_length_end
        new(0, number_agents_iterator, 0, memory_length_iterator, memory_init_state, 0.0, error_list, 0, 0.0,  tag1, tag2, tag1_proportion, averager, random_seed)
    end
end