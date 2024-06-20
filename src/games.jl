#constructor for specific game to be played
const PayoffMatrix{S1, S2, L} = SMatrix{S1, S2, Tuple{Int, Int}, L}
const StrategySet{L} = SVector{L, Int8}


"""
    Game{S1, S2, L}

Basic Game type with row dimension S1, column dimension S2, and length L=S1*S2.
"""
struct Game{S1, S2, L}
    name::String
    payoff_matrix::PayoffMatrix{S1, S2, L} #want to make this parametric (for any int size to be used) #NEED TO MAKE THE SMATRIX SIZE PARAMETRIC AS WELL? Normal Matrix{Tuple{Int8, Int8}} doesnt work with JSON3.read()
    # strategies::Tuple{StrategySet{S1}, StrategySet{S2}}                #NEED TO MAKE PLAYER 1 STRATEGIES AND PLAYER 2 STRATEGIES TO ACCOUNT FOR VARYING SIZED PAYOFF MATRICES #NOTE: REMOVE THIS (strategies are inherent in payoff_matrix)

    function Game{S1, S2}(name::String, payoff_matrix::Matrix{Tuple{Int, Int}}) where {S1, S2}
        L = S1 * S2
        static_payoff_matrix = SMatrix{S1, S2, Tuple{Int, Int}, L}(payoff_matrix)
        # strategies = (Tuple(Int8(n) for n in 1:S1), Tuple(Int8(n) for n in 1:S2))
        return new{S1, S2, L}(name, static_payoff_matrix)
    end
    function Game(name::String, payoff_matrix::Matrix{Tuple{Int, Int}})
        matrix_size = size(payoff_matrix)
        S1 = matrix_size[1]
        S2 = matrix_size[2]
        L = S1 * S2
        static_payoff_matrix = SMatrix{S1, S2, Tuple{Int, Int}, L}(payoff_matrix)
        # strategies = (Tuple(Int8(n) for n in 1:S1), Tuple(Int8(n) for n in 1:S2)) #create integer strategies that correspond to row/column indices of payoff_matrix
        return new{S1, S2, L}(name, static_payoff_matrix)
    end
    function Game(name::String, payoff_matrix::Matrix{Int}) #for a zero-sum payoff matrix ########################## MUST FIX THIS!!!!!!!! #####################
        matrix_size = size(payoff_matrix) #need to check size of each dimension bc payoff matrices don't have to be perfect squares
        S1 = matrix_size[1]
        S2 = matrix_size[2]
        L = S1 * S2
        # strategies = (Tuple(Int8(n) for n in 1:S1), Tuple(Int8(n) for n in 1:S2)) #create integer strategies that correspond to row/column indices of payoff_matrix
        indices = CartesianIndices(payoff_matrix)
        tuple_vector = Vector{Tuple{Int, Int}}([])
        for index in indices
            new_tuple = Tuple{Int, Int}([payoff_matrix[index], -payoff_matrix[index]])
            push!(tuple_vector, new_tuple)
        end
        new_payoff_matrix = reshape(tuple_vector, matrix_size)
        return new{S1, S2, L}(name, new_payoff_matrix)
    end
    # function Game{S1, S2, L}(name::String, payoff_matrix::SMatrix{S1, S2, Tuple{Int8, Int8}}, strategies::Tuple{SVector{S1, Int8}, SVector{S2, Int8}}) where {S1, S2, L} ##this method needed for reconstructing with JSON3
    #     return new{S1, S2, L}(name, payoff_matrix, strategies)
    # end
end



##########################################
# Game Accessors
##########################################

"""
    displayname(game::Game)

Get the name of a game instance.
"""
displayname(game::Game) = getfield(game, :name)

"""
    payoff_matrix(game::Game)

Get the payoff matrix for a game.
"""
payoff_matrix(game::Game) = getfield(game, :payoff_matrix)

"""
    strategies(game::Game)

Get the possible strategies for each player that can be played in a game.
"""
strategies(game::Game) = axes(payoff_matrix(game))

"""
    strategies(game::Game, player_number::Int)

Get the possible strategies for the given player that can be played in a game.
"""
strategies(game::Game, player_number::Int) = getindex(strategies(game), player_number) #NOTE: player number must be within dimensions of payoff_matrix. Might want to go through and do error handling stuff

"""
    random_strategy(game::Game, player_number::Int)

Get a random strategy from the possible strategies that a player can play in a game.
"""
random_strategy(game::Game, player_number::Int) = rand(strategies(game, player_number))


Base.show(game::Game) = println(displayname(game))
