

#constructor for individual agents with relevant fields (mutable to update object later)
mutable struct Agent
    name::String
    tag::String
    wealth::Int
    memory::Vector{Tuple{String, Int}}

    function Agent(name, tag)
        return new(name, tag, 0, Vector{Int}([]))
    end
    function Agent()
        return new("", "", 0, Vector{Int}([]))
    end
end

#constructor for specific game to be played (mutable to update object later)
mutable struct Game
    name::String
    payoff_matrix::Matrix{Tuple{Int64, Int64}}
    strategies::Vector{Int64}
    player1::Agent
    player2::Agent

    function Game(name, payoff_matrix, strategies)
        new(name, payoff_matrix, strategies, Agent(), Agent())
    end
end

mutable struct SimParams
    number_agents::Int64
    memory_length::Int64
    error::Float64
    matches_per_period::Int64
    tag_proportion::Float64
    sufficient_equity::Float64
    tag1::AbstractString
    tag2::AbstractString
    m_init::AbstractString
    iterationParam::Symbol
    iterator::StepRange
    error_list::Vector{Float64}
    averager::Int32
end