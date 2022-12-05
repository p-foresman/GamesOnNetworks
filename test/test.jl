using Combinatorics, BenchmarkTools
include("../src/types.jl")
include("../src/setup_params.jl")

payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])
#Check "global_StructTypes.jl" file and ensure that the size of this payoff matrix is listed under the "Game type" section


#create bargaining game type (players will be slotted in)
const game = Game("Bargaining Game", payoff_matrix)
const sim_params = SimParams(number_agents=20, memory_length=10, memory_init_state=:fractious, error=0.0, tag1=:red, tag2=:blue, tag1_proportion=1.0, random_seed=1234)
const agent1 = Agent("1", :red, 0, [(:red, Int8(2)),(:red, Int8(2)),(:red, Int8(3)),(:red, Int8(2)),(:red, Int8(1)),(:red, Int8(2)),(:red, Int8(3)),(:red, Int8(2)),(:red, Int8(1)),(:red, Int8(2))])
const agent2 = Agent("2", :red, 0, [(:red, Int8(2)),(:red, Int8(2)),(:red, Int8(1)),(:red, Int8(1)),(:red, Int8(1)),(:red, Int8(1)),(:red, Int8(3)),(:red, Int8(3)),(:red, Int8(1)),(:red, Int8(3))])

# memory_lengths = 7:20

function makeChoiceTest(game::Game, memory_state)
    opponent_strategy_recollection = [count(i->(i==strategy), memory_state) for strategy in game.strategies[1]]
    player_memory_length = sum(opponent_strategy_recollection)
    opponent_strategy_probs = [i / player_memory_length for i in opponent_strategy_recollection]
    player_expected_utilities = zeros(Float32, length(game.strategies[1]))

    #### WINNER ####
    for column in 1:size(game.payoff_matrix, 2) #column strategies
        for row in 1:size(game.payoff_matrix, 1) #row strategies
            player_expected_utilities[row] += game.payoff_matrix[row, column][1] * opponent_strategy_probs[column]
        end
    end


    #this should be equivalent to above. make sure and see which is more efficient
    # for index in CartesianIndices(game.payoff_matrix) #index in form (row, column)
    #     player_expected_utilities[index[1]] += game.payoff_matrix[index][1] * opponent_strategy_probs[index[2]]
    # end

    ####!!!! AN ATTEMPT TO VECTORIZE THIS OPERATION !!!!####
    # player_expected_utilities[1] = [(opponent_strategy_probs[2] .* game.payoff_matrix)]
    # player_expected_utilities[2] = transpose(opponent_strategy_probs[1]) .* game.payoff_matrix

    player_max_value = maximum(player_expected_utilities)
    player_max_strategies = findall(i->(i==player_max_value), player_expected_utilities)
    player_choice = Int8(rand(player_max_strategies))

    return player_choice, player_choice
end




function choiceTendancy(game::Game, memory_length::Integer)
    memory_state_sets = collect(with_replacement_combinations(game.strategies[1], memory_length)) #gives all possible memory states given a memory length
    choices_list = []
    mwe_test = []
    for memory_state in memory_state_sets
        choice, test = makeChoiceTest(game, memory_state)
        append!(choices_list, choice)
        append!(mwe_test, test)
    end
    choices_count = [count(i->(i==strategy), choices_list) for strategy in game.strategies[1]]
    choices_proportions = [i / length(memory_state_sets) for i in choices_count]
    return choices_proportions, mwe_test
end

# choice_proportions_list = []
# for memory_length in memory_lengths
#     choice_proportions = choiceTendancy(game, memory_length)
#     append!(choice_proportions_list, choice_proportions)
# end
# println(choice_proportions_list)
# choice_tendancies, mwe = choiceTendancy(game, 20)
# choice_tendancies2, mwe2 = choiceTendancy(game, 20)




function settingsImportTest(settings_filename::String)
    include("settings/$settings_filename")
    for (i, val) in enumerate(x)
        y = val + i
    end
end



using TimerOutputs
const test_times = TimerOutput()


#choice algorithm for agents "deciding" on strategies (find max expected payoff)
function makeChoices(game::Game, sim_params::SimParams, players::Tuple{Agent, Agent}) #COULD LIKELY MAKE THIS FUNCTION BETTER. Could use CartesianIndices() to iterate through payoff matrix? 
@timeit test_times "makeChoices" begin
    player_choices::Vector{Int8} = [rand(game.strategies[1]), rand(game.strategies[2])]
    
    function findOpponentStrategyProbs(player_memory, opponent_tag, opponent_strategies)
        opponent_strategy_recollection = zero.(opponent_strategies)
        for memory in player_memory
            if memory[1] == opponent_tag #if the opponent's tag is not present, no need to count strategies
                for strategy in opponent_strategies
                    if memory[2] == strategy
                        opponent_strategy_recollection[strategy] += 1 #strategy is simply the payoff_matrix index for the given dimension. Will remove explicit strategies eventually
                        break
                    end
                end
            end
        end
        return opponent_strategy_recollection ./ sum(opponent_strategy_recollection)
    end

    # opponent_strategy_recollections = @timeit test_times "opponent_strategy_recollections" [[count(i->(i[1]==players[2].tag && i[2]==strategy), players[1].memory) for strategy in game.strategies[2]], [count(i->(i[1]==players[1].tag && i[2]==strategy), players[2].memory) for strategy in game.strategies[1]]]
    #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
    #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
    #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.
    # @timeit test_times "opponent_strategy_probs" begin
    # opponent_strategy_probs_1 = findOpponentStrategyProbs(players[1].memory, players[2].tag, axes(game.payoff_matrix, 2))
    # findOpponentStrategyProbs(players[1].memory, players[2].tag, axes(game.payoff_matrix, 2))
    # end
    # opponent_strategy_probs = @timeit test_times "opponent_strategy_probs" [opponent_strategy_recollections[player] ./ sum(opponent_strategy_recollections[player]) for player in eachindex(players)] #sum(opponent_strategy_recollections) counts effective memory length
    
    # opponent_strategy_probs = opponent_strategy_recollections
    # @timeit test_times "opponent_strategy_probs" begin
    # opponent_strategy_probs .= opponent_strategy_recollections ./ sum.(opponent_strategy_recollections)
    # end
    # function getOpponentProbs!(strategy_recollections)
    #     opponent_strategy_recollections .= opponent_strategy_recollections ./ sum.(opponent_strategy_recollections)
    # end

    player_expected_utilities = @timeit test_times "player_expected_utilities" zeros.(Float32, length.(game.strategies))
    function findExpectedUtilities!(expected_utilities, payoff_matrix, opponent_probs_1, opponent_probs_2)
        for column in axes(payoff_matrix, 2) #column strategies
            for row in axes(payoff_matrix, 1) #row strategies
                expected_utilities[1][row] += payoff_matrix[row, column][1] * opponent_probs_1[column]
                expected_utilities[2][column] += payoff_matrix[row, column][2] * opponent_probs_2[row]
            end
        end
    end
    @timeit test_times "mainloop" findExpectedUtilities!(player_expected_utilities, game.payoff_matrix, findOpponentStrategyProbs(players[1].memory, players[2].tag, axes(game.payoff_matrix, 2)), findOpponentStrategyProbs(players[2].memory, players[1].tag, axes(game.payoff_matrix, 1)))


    # @timeit test_times "mainloop" begin
    # for column in 1:size(game.payoff_matrix, 2) #column strategies
    #     for row in 1:size(game.payoff_matrix, 1) #row strategies
    #         player_expected_utilities[1][row] += game.payoff_matrix[row, column][1] * opponent_strategy_probs[1][column]
    #         player_expected_utilities[2][column] += game.payoff_matrix[row, column][2] * opponent_strategy_probs[2][row]
    #     end
    # end
    # end

    #this is equivalent to above. slightly faster (very slightly), but makes more allocations
    # for index in CartesianIndices(game.payoff_matrix) #index in form (row, column)
    #     player_expected_utilities[1][index[1]] += game.payoff_matrix[index][1] * opponent_strategy_probs[1][index[2]]
    #     player_expected_utilities[2][index[2]] += game.payoff_matrix[index][2] * opponent_strategy_probs[2][index[1]]
    # end

    ####!!!! AN ATTEMPT TO VECTORIZE THIS OPERATION !!!!#### (currently slower)
    # player_expected_utilities_test = Vector{Vector{Float32}}([])
    # push!(player_expected_utilities_test, vec(sum(transpose(opponent_strategy_probs[1]) .* getindex.(game.payoff_matrix, 1), dims=2)))
    # push!(player_expected_utilities_test, vec(sum(opponent_strategy_probs[2] .* getindex.(game.payoff_matrix, 2), dims=1)))
    
    function findMaximumStrats(expected_utilities::Vector{Float32})
        max_strats::Vector{Int8} = []
        max = maximum(expected_utilities)
        for i in eachindex(expected_utilities)
            if expected_utilities[i] == max
                push!(max_strats, Int8(i))
            end
        end
        return rand(max_strats)
    end

    # player_max_values = @timeit test_times "player_max_values" maximum.(player_expected_utilities)
    # player_max_strategies = @timeit test_times "player_max_strategies" [findall(i->(i==player_max_values[player]), player_expected_utilities[player]) for player in eachindex(players)] #findall(i->(i==maximum(player_expected_utilities[player]))
    # player_choices = @timeit test_times "player_choices" Int8.(rand.(player_max_strategies))
    # println(player_max_strategies)
    @timeit test_times "player_choices with rand" begin
    for player in eachindex(players)
        if (rand() > sim_params.error) player_choices[player] = findMaximumStrats(player_expected_utilities[player]) end #if rand() <= error, do nothing (i.e., keep random choice)
    end
    end
    return player_choices
    # print("memory length: ")
    # println(player_memory_lengths)
    # println("decision process here...")
    # print("recollection: ")
    # println(opponent_strategy_recollections)
    # print("probs: ")
    # println(opponent_strategy_probs)
    # print("utilities: ")
    # println(player_expected_utilities)
    # print("max strategy values: ")
    # println(player_max_values)
    # print("max strategy indices: ")
    # println(player_max_strategies)
    # print("player choices: ")
    # println(typeof(player_choices))
# @timeit test_times "randLoop" begin
#     for player in eachindex(players)
#         if rand() <= sim_params.error
#             player_choices[player] = rand(game.strategies[player])
#         end
#     end
# end
    
    # outcome = game.payoff_matrix[player_choices[1], player_choices[2]] #don't need this right now (wealth is not being analyzed)
    # players[1].wealth += outcome[1]
    # players[2].wealth += outcome[2]

    # print("player choices post random: ")
    # println(player_choices)
    # print("outcome: ")
    # println(outcome)
end
end

function makeChoicesLoop(game::Game, sim_params::SimParams, players::Tuple{Agent, Agent})
@timeit test_times "makeChoicesLoop" begin
    for i in 1:1000000
        makeChoices(game, sim_params, players)
    end
end
end

function makeChoicesLoop_old(game::Game, sim_params::SimParams, players::Tuple{Agent, Agent})
@timeit test_times "makeChoicesLoop_old" begin
    for i in 1:1000000
        makeChoices_old(game, sim_params, players)
    end
end
end
















#choice algorithm for agents "deciding" on strategies (find max expected payoff)
function makeChoices_old(game::Game, sim_params::SimParams, players::Tuple{Agent, Agent}) #COULD LIKELY MAKE THIS FUNCTION BETTER. Could use CartesianIndices() to iterate through payoff matrix? 
    @timeit test_times "makeChoices" begin
        player_choices::Vector{Int8} = [rand(game.strategies[1]), rand(game.strategies[2])]
        
        opponent_strategy_recollections = @timeit test_times "opponent_strategy_recollections" [[count(i->(i[1]==players[2].tag && i[2]==strategy), players[1].memory) for strategy in game.strategies[2]], [count(i->(i[1]==players[1].tag && i[2]==strategy), players[2].memory) for strategy in game.strategies[1]]]
        #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
        #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
        #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.
    
        opponent_strategy_probs = @timeit test_times "opponent_strategy_probs" [opponent_strategy_recollections[player] ./ sum(opponent_strategy_recollections[player]) for player in eachindex(players)] #sum(opponent_strategy_recollections) counts effective memory length
        
        # opponent_strategy_probs = opponent_strategy_recollections
        # @timeit test_times "opponent_strategy_probs" begin
        # opponent_strategy_probs .= opponent_strategy_recollections ./ sum.(opponent_strategy_recollections)
        # end
        # function getOpponentProbs!(strategy_recollections)
        #     opponent_strategy_recollections .= opponent_strategy_recollections ./ sum.(opponent_strategy_recollections)
        # end
    
        player_expected_utilities = @timeit test_times "player_expected_utilities" zeros.(Float32, length.(game.strategies))
        function findExpectedUtilities!(expected_utilities, payoff_matrix, opponent_probs)
            for column in axes(payoff_matrix, 2) #column strategies
                for row in axes(payoff_matrix, 1) #row strategies
                    expected_utilities[1][row] += payoff_matrix[row, column][1] * opponent_probs[1][column]
                    expected_utilities[2][column] += payoff_matrix[row, column][2] * opponent_probs[2][row]
                end
            end
        end
        @timeit test_times "mainloop" findExpectedUtilities!(player_expected_utilities, game.payoff_matrix, opponent_strategy_probs)
    
    
        # @timeit test_times "mainloop" begin
        # for column in 1:size(game.payoff_matrix, 2) #column strategies
        #     for row in 1:size(game.payoff_matrix, 1) #row strategies
        #         player_expected_utilities[1][row] += game.payoff_matrix[row, column][1] * opponent_strategy_probs[1][column]
        #         player_expected_utilities[2][column] += game.payoff_matrix[row, column][2] * opponent_strategy_probs[2][row]
        #     end
        # end
        # end
    
        #this is equivalent to above. slightly faster (very slightly), but makes more allocations
        # for index in CartesianIndices(game.payoff_matrix) #index in form (row, column)
        #     player_expected_utilities[1][index[1]] += game.payoff_matrix[index][1] * opponent_strategy_probs[1][index[2]]
        #     player_expected_utilities[2][index[2]] += game.payoff_matrix[index][2] * opponent_strategy_probs[2][index[1]]
        # end
    
        ####!!!! AN ATTEMPT TO VECTORIZE THIS OPERATION !!!!#### (currently slower)
        # player_expected_utilities_test = Vector{Vector{Float32}}([])
        # push!(player_expected_utilities_test, vec(sum(transpose(opponent_strategy_probs[1]) .* getindex.(game.payoff_matrix, 1), dims=2)))
        # push!(player_expected_utilities_test, vec(sum(opponent_strategy_probs[2] .* getindex.(game.payoff_matrix, 2), dims=1)))
        
        function findMaximumStrats(expected_utilities::Vector{Float32})
            max_strats::Vector{Int8} = []
            max = maximum(expected_utilities)
            for i in eachindex(expected_utilities)
                if expected_utilities[i] == max
                    push!(max_strats, Int8(i))
                end
            end
            return rand(max_strats)
        end
    
        # player_max_values = @timeit test_times "player_max_values" maximum.(player_expected_utilities)
        # player_max_strategies = @timeit test_times "player_max_strategies" [findall(i->(i==player_max_values[player]), player_expected_utilities[player]) for player in eachindex(players)] #findall(i->(i==maximum(player_expected_utilities[player]))
        # player_choices = @timeit test_times "player_choices" Int8.(rand.(player_max_strategies))
        # println(player_max_strategies)
        @timeit test_times "player_choices with rand" begin
        if (rand() > sim_params.error) player_choices[1] = findMaximumStrats(player_expected_utilities[1]) end #if rand() <= error, do nothing (i.e., keep random choice)
        if (rand() > sim_params.error) player_choices[2] = findMaximumStrats(player_expected_utilities[2]) end
        end
        return player_choices
        # print("memory length: ")
        # println(player_memory_lengths)
        # println("decision process here...")
        # print("recollection: ")
        # println(opponent_strategy_recollections)
        # print("probs: ")
        # println(opponent_strategy_probs)
        # print("utilities: ")
        # println(player_expected_utilities)
        # print("max strategy values: ")
        # println(player_max_values)
        # print("max strategy indices: ")
        # println(player_max_strategies)
        # print("player choices: ")
        # println(typeof(player_choices))
    # @timeit test_times "randLoop" begin
    #     for player in eachindex(players)
    #         if rand() <= sim_params.error
    #             player_choices[player] = rand(game.strategies[player])
    #         end
    #     end
    # end
        
        # outcome = game.payoff_matrix[player_choices[1], player_choices[2]] #don't need this right now (wealth is not being analyzed)
        # players[1].wealth += outcome[1]
        # players[2].wealth += outcome[2]
    
        # print("player choices post random: ")
        # println(player_choices)
        # print("outcome: ")
        # println(outcome)
    end
    end






























































#choice algorithm for agents "deciding" on strategies (find max expected payoff)
function makeChoices_for_single_player_revision(game::Game, sim_params::SimParams, players::Tuple{Agent, Agent}) #COULD LIKELY MAKE THIS FUNCTION BETTER. Could use CartesianIndices() to iterate through payoff matrix? 
    player_choices::Vector{Int8} = [rand(game.strategies[1]), rand(game.strategies[2])]
    if rand() <= sim_params.error
        return player_choices
        # print("player_choices rand: ")
        # println(player_choices)
    else
        opponent_strategy_recollections = [[count(i->(i[1]==players[2].tag && i[2]==strategy), players[1].memory) for strategy in game.strategies[2]], [count(i->(i[1]==players[1].tag && i[2]==strategy), players[2].memory) for strategy in game.strategies[1]]]
        # print("opponent_strategy_recollections: ")
        # println(opponent_strategy_recollections)
        #if a player has no memories and/or no memories of the opponents 'tag' type, their opponent_strategy_recollections entry will be a Tuple of zeros.
        #this will cause their opponent_strategy_probs to also be a Tuple of zeros, giving the player no "insight" while playing the game.
        #since the player's expected utility list will then all be equal (zeros), the player makes a random choice.

        opponent_strategy_probs = [opponent_strategy_recollections[player] ./ sum(opponent_strategy_recollections[player]) for player in eachindex(players)] #sum(opponent_strategy_recollections) counts effective memory length
        # print("opponent_strategy_probs: ")
        # println(opponent_strategy_probs)

        player_expected_utilities = zeros.(Float32, length.(game.strategies))
        function findExpectedUtilities!(expected_utilities, payoff_matrix, opponent_probs)
            for column in axes(payoff_matrix, 2) #column strategies
                for row in axes(payoff_matrix, 1) #row strategies
                    expected_utilities[1][row] += payoff_matrix[row, column][1] * opponent_probs[1][column]
                    expected_utilities[2][column] += payoff_matrix[row, column][2] * opponent_probs[2][row]
                end
            end
        end
        findExpectedUtilities!(player_expected_utilities, game.payoff_matrix, opponent_strategy_probs)
        # print("player_expected_utilities: ")
        # println(player_expected_utilities)
        
        function findMaximumStrats(expected_utilities::Vector{Float32})
            max_strats::Vector{Int8} = []
            max = maximum(expected_utilities)
            for i in eachindex(expected_utilities)
                if expected_utilities[i] == max
                    push!(max_strats, Int8(i))
                end
            end
            # print("max_strats: ")
            # println(max_strats)
            return rand(max_strats)
        end
        player_choices[1] = findMaximumStrats(player_expected_utilities[1])
        player_choices[2] = findMaximumStrats(player_expected_utilities[2])
        # print("player_choices: ")
        # println(player_choices)
        return player_choices

        # outcome = game.payoff_matrix[player_choices[1], player_choices[2]] #don't need this right now (wealth is not being analyzed)
        # players[1].wealth += outcome[1]
        # players[2].wealth += outcome[2]
    end
end