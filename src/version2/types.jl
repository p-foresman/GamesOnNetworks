using StructTypes, Random

#constructor for individual agents with relevant fields (mutable to update object later)
mutable struct Agent
    name::AbstractString
    tag::Symbol
    wealth::Int #is this necessary?
    memory::Vector{Tuple{Symbol, Int8}}

    function Agent(name::AbstractString, tag::Symbol, wealth::Int, memory::Vector{Tuple{Symbol, Int8}})
        return new(name, tag, wealth, memory)
    end
    function Agent(name::AbstractString, tag::Symbol)
        return new(name, tag, 0, Vector{Tuple{Symbol, Int8}}([]))
    end
    function Agent()
        return new("", Symbol(), 0, Vector{Tuple{Symbol, Int8}}([]))
    end
end
StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable() #global declaration needed to read and write with JSON3 package

#constructor for specific game to be played (mutable to update object later)
mutable struct Game
    name::AbstractString
    payoff_matrix::Matrix{Tuple{Int8, Int8}} #want to make this parametric (for any int size to be used)
    strategies::Tuple{Int8, Int8, Int8}
    player1::Agent #would probably be better to keep the players out of the Game struct. Could then use JSON3 to directly translate Game struct back and forth from json string for DB storage
    player2::Agent

    function Game(name::String, payoff_matrix::Matrix{Tuple{Int8, Int8}})
        strategies = Tuple(Int8(n) for n in 1:size(payoff_matrix, 1)) #create integer strategies that correspond to row/column indices of payoff_matrix
        new(name, payoff_matrix, strategies, Agent(), Agent())
    end
    function Game(name::String, payoff_matrix::Matrix{Int8}) #for a zero-sum payoff matrix
        matrix_size = size(payoff_matrix) #need to check size of each dimension bc payoff matrices don't have to be perfect squares
        strategies = Tuple(Int8(n) for n in 1:matrix_size[1])
        indices = CartesianIndices(payoff_matrix)
        tuple_vector = Vector{Tuple{Int8, Int8}}([])
        for i in indices
            new_tuple = Tuple{Int8, Int8}([payoff_matrix[i[1], i[2]], -payoff_matrix[i[1], i[2]]])
            push!(tuple_vector, new_tuple)
        end
        new_payoff_matrix = reshape(tuple_vector, matrix_size)
        return new(name, new_payoff_matrix, strategies, Agent(), Agent())
    end
    Game() = new()
end
StructTypes.StructType(::Type{Game}) = StructTypes.Mutable() #global declaration needed to read and write with JSON3 package

mutable struct SimParams
    number_agents::Int64
    memory_length::Int64
    memory_init_state::Symbol
    error::Float64 #will be initialized at 0.0 and updated based on error_list value (list iterated over)
    matches_per_period::Int64 #will be initialized at 0 and updated based on floor(number_agents/2) value in simulation
    sufficient_equity::Float64 #will be initialized at 0.0 and updated based on (1-error)*memory_length value in simulation
    tag1::Symbol #could make tags a vararg to have any given number of tags
    tag2::Symbol
    tag1_proportion::Float64
    random_seed::Int64 #probably don't need a random seed in every SimParams struct

    #all keyword arguments
    function SimParams(;number_agents::Int64, memory_length::Int64, memory_init_state::Symbol, error::Float64, tag1::Symbol, tag2::Symbol, tag1_proportion::Float64, random_seed::Int64)
        matches_per_period = floor(number_agents / 2)
        sufficient_equity = (1 - error) * memory_length
        new(number_agents, memory_length, memory_init_state, error, matches_per_period, sufficient_equity, tag1, tag2, tag1_proportion, random_seed)
    end
    SimParams() = new()
end
StructTypes.StructType(::Type{SimParams}) = StructTypes.Mutable() #global declaration needed to read and write with JSON3 package

StructTypes.StructType(::Type{Random.Xoshiro}) = StructTypes.Mutable() #needed to read and write the state of the Xoshiro RNG with JSON3 package