using Combinatorics
include("types.jl")

payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])
#Check "global_StructTypes.jl" file and ensure that the size of this payoff matrix is listed under the "Game type" section


#create bargaining game type (players will be slotted in)
game = Game("Bargaining Game", payoff_matrix)

memory_lengths = 7:20

function makeChoiceTest(game::Game, memory_state)
    opponent_strategy_recollection = [count(i->(i==strategy), memory_state) for strategy in game.strategies[1]]

    player_memory_length = sum(opponent_strategy_recollection)
    opponent_strategy_probs = [i / player_memory_length for i in opponent_strategy_recollection]
    player_expected_utilities = zeros(Float32, length(game.strategies[1]))


    #this should be equivalent to above. make sure and see which is more efficient
    for index in CartesianIndices(game.payoff_matrix) #index in form (row, column)
        player_expected_utilities[index[1]] += game.payoff_matrix[index][1] * opponent_strategy_probs[index[2]]
    end

    ####!!!! AN ATTEMPT TO VECTORIZE THIS OPERATION !!!!####
    # player_expected_utilities[1] = [(opponent_strategy_probs[2] .* game.payoff_matrix)]
    # player_expected_utilities[2] = transpose(opponent_strategy_probs[1]) .* game.payoff_matrix

    player_max_value = maximum(player_expected_utilities)
    player_max_strategies = findall(i->(i==player_max_value), player_expected_utilities)
    player_choice = Int8(rand(player_max_strategies))

    return player_choice
end


function choiceTendancy(game::Game, memory_length::Integer)
    memory_state_sets = collect(with_replacement_combinations(game.strategies[1], memory_length)) #gives all possible memory states given a memory length
    choices_list = []
    for memory_state in memory_state_sets
        choice = makeChoiceTest(game, memory_state)
        append!(choices_list, choice)
    end
    choices_count = [count(i->(i==strategy), choices_list) for strategy in game.strategies[1]]
    choices_proportions = [i / length(memory_state_sets) for i in choices_count]
    return choices_proportions
end

# choice_proportions_list = []
# for memory_length in memory_lengths
#     choice_proportions = choiceTendancy(game, memory_length)
#     append!(choice_proportions_list, choice_proportions)
# end
# println(choice_proportions_list)
println(choiceTendancy(game, 20))




