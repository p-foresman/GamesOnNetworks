using StructTypes

#constructor for individual agents with relevant fields (mutable to update object later)
mutable struct Agent
    name::AbstractString
    tag::Symbol
    wealth::Int #is this necessary?
    memory::Vector{Tuple{Symbol, Int}}

    function Agent(name::AbstractString, tag::Symbol, wealth::Int, memory::Vector{Tuple{Symbol, Int}})
        return new(name, tag, wealth, memory)
    end
    function Agent(name::AbstractString, tag::Symbol)
        return new(name, tag, 0, Vector{Int}([]))
    end
    function Agent()
        return new("", Symbol(), 0, Vector{Tuple{Symbol, Int}}([]))
    end
end
StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable() #global declaration needed to read and write with JSON3 package

#constructor for specific game to be played (mutable to update object later)
mutable struct Game
    name::AbstractString
    payoff_matrix::Matrix{Tuple{Int64, Int64}} #Could make this Int8?
    strategies::Tuple{Int8, Int8, Int8}
    player1::Agent
    player2::Agent

    function Game(name::AbstractString, payoff_matrix::Matrix{Tuple{Int64, Int64}})
        strategies = Tuple(Int8(n) for n in 1:size(payoff_matrix, 1)) #create integer strategies that correspond to row/column indices of payoff_matrix
        new(name, payoff_matrix, strategies, Agent(), Agent())
    end
    Game() = new()
end
StructTypes.StructType(::Type{Game}) = StructTypes.Mutable() #global declaration needed to read and write with JSON3 package

mutable struct SimParams
    number_agents::Int16
    memory_length::Int16
    memory_init_state::Symbol
    error::Float64 #will be initialized at 0.0 and updated based on error_list value (list iterated over)
    matches_per_period::Int32 #will be initialized at 0 and updated based on floor(number_agents/2) value in simulation
    sufficient_equity::Float64 #will be initialized at 0.0 and updated based on (1-error)*memory_length value in simulation
    tag1::Symbol #could make tags a vararg to have any given number of tags
    tag2::Symbol
    tag1_proportion::Float64
    random_seed::Int16

    #all keyword arguments
    function SimParams(;number_agents::Int , memory_length::Int, memory_init_state::Symbol, error::Float64, tag1::Symbol, tag2::Symbol, tag1_proportion::Float64, random_seed::Int)
        matches_per_period = floor(number_agents / 2)
        sufficient_equity = (1 - error) * memory_length
        new(Int16(number_agents), Int16(memory_length), memory_init_state, error, matches_per_period, sufficient_equity, tag1, tag2, tag1_proportion, Int16(random_seed))
    end
    SimParams() = new()
end
StructTypes.StructType(::Type{SimParams}) = StructTypes.Mutable() #global declaration needed to read and write with JSON3 package