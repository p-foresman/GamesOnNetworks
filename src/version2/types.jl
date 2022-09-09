using StructTypes, Random, StaticArrays

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

#= #constructor for specific game to be played (mutable to update object later)
struct Game
    name::AbstractString
    payoff_matrix::SMatrix{3, 3, Tuple{Int8, Int8}, 9} #want to make this parametric (for any int size to be used) #NEED TO MAKE THE SMATRIX SIZE PARAMETRIC AS WELL? Normal Matrix{Tuple{Int8, Int8}} doesnt work with JSON3.read()
    strategies::Tuple{Int8, Int8, Int8}                 #COULD DEFINE A SIZE FIELD THAT CONTAINS A Tuple{Int, Int} WITH DIMENSIONS OF MATRIX TO ALSO BE STORED IN DB

    function Game(name::String, payoff_matrix::SMatrix{3, 3, Tuple{Int8, Int8}, 9})
        strategies = Tuple(Int8(n) for n in 1:size(payoff_matrix, 1)) #create integer strategies that correspond to row/column indices of payoff_matrix
        new(name, payoff_matrix, strategies)
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
        return new(name, new_payoff_matrix, strategies)
    end
    function Game(name::String, payoff_matrix::SMatrix{3, 3, Tuple{Int8, Int8}, 9}, strategies::Tuple{Int8, Int8, Int8})
        return new(name, payoff_matrix, strategies)
    end
end
StructTypes.StructType(::Type{Game}) = StructTypes.Struct() #global declaration needed to read and write with JSON3 package =#





#constructor for specific game to be played
struct Game{S1, S2}
    name::AbstractString
    payoff_matrix::SMatrix{S1, S2, Tuple{Int8, Int8}} #want to make this parametric (for any int size to be used) #NEED TO MAKE THE SMATRIX SIZE PARAMETRIC AS WELL? Normal Matrix{Tuple{Int8, Int8}} doesnt work with JSON3.read()
    strategies1::SVector{S1, Int8}                 #NEED TO MAKE PLAYER 1 STRATEGIES AND PLAYER 2 STRATEGIES TO ACCOUNT FOR VARYING SIZED PAYOFF MATRICES
    strategies2::SVector{S2, Int8}

    function Game(name::String, payoff_matrix::Matrix{Tuple{Int8, Int8}})
        matrix_size = size(payoff_matrix)
        S1 = matrix_size[1]
        S2 = matrix_size[2]
        static_payoff_matrix = SMatrix{S1, S2, Tuple{Int8, Int8}}(payoff_matrix)
        strategies1 = Tuple(Int8(n) for n in 1:S1) #create integer strategies that correspond to row/column indices of payoff_matrix
        strategies2 = Tuple(Int8(n) for n in 1:S2)
        new{S1, S2}(name, static_payoff_matrix, strategies1, strategies2)
    end
    function Game(name::String, payoff_matrix::Matrix{Int8}) #for a zero-sum payoff matrix ########################## MUST FIX THIS!!!!!!!! #####################
        matrix_size = size(payoff_matrix) #need to check size of each dimension bc payoff matrices don't have to be perfect squares
        S1 = matrix_size[1]
        S2 = matrix_size[2]
        strategies1 = Tuple(Int8(n) for n in 1:S1) #create integer strategies that correspond to row/column indices of payoff_matrix
        strategies2 = Tuple(Int8(n) for n in 1:S2)
        indices = CartesianIndices(payoff_matrix)
        tuple_vector = Vector{Tuple{Int8, Int8}}([])
        for i in indices
            new_tuple = Tuple{Int8, Int8}([payoff_matrix[i[1], i[2]], -payoff_matrix[i[1], i[2]]])
            push!(tuple_vector, new_tuple)
        end
        new_payoff_matrix = reshape(tuple_vector, matrix_size)
        return new{S1, S2}(name, new_payoff_matrix, strategies1, strategies2)
    end
    function Game{S1, S2}(name::String, payoff_matrix::SMatrix{S1, S2, Tuple{Int8, Int8}}, strategies1::SVector{S1, Int8}, strategies2::SVector{S2, Int8}) where {S1, S2} ##this method needed for reconstructing with JSON3
        return new{S1, S2}(name, payoff_matrix, strategies1, strategies2)
    end
end






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

#include the global definitions for StructTypes (more global definitions can be added in the file)
include("settings/global_StructTypes.jl")