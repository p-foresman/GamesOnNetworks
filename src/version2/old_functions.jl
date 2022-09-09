
#choice algorithm for agents "deciding" on strategies (find max expected payoff)
function makeChoice(game::Game, players::Tuple{Agent, Agent}; player_number::Int8) #COULD LIKELY MAKE THIS FUNCTION BETTER. Could use CartesianIndices() to iterate through payoff matrix?
    if player_number == 1
        player = players[1]
        player_strategies = game.strategies[1]
        opponent = players[2]
        opponent_strategies = game.strategies[2]
    else
        player = players[2]
        player_strategies = game.strategies[2]
        opponent = players[1]
        opponent_strategies = game.strategies[1]
    end
    player_memory_length = count(i->(i[1] == opponent.tag), player.memory) #tag specific! (these should both work fine without tags too)
    #print("memory length: ")
    #println(memory_length)
    player_recollection = [count(i->(i[1]==opponent.tag && i[2]==strategy), player.memory) for strategy in opponent_strategies]
    #println("decision process here...")
    #print("recollection: ")
    #println(player_recollection)
    opponent_probs = [i / player_memory_length for i in player_recollection]
    #print("probs: ")
    #println(opponent_probs)
    
    expected_utilities = zeros(Float32, length(player_strategies))
    for i in eachindex(game.strategies[1]) #row strategies
        for j in eachindex(game.strategies[2]) #column strategies
            if player_number == 1
                expected_utilities[i] += game.payoff_matrix[i, j][player_number] * opponent_probs[j]
            else
                expected_utilities[j] += game.payoff_matrix[i, j][player_number] * opponent_probs[i]
            end
        end
    end
    #println(player_number)
    #print("utilities: ")
    #println(expected_utilities)
    max_value = maximum(expected_utilities)
    #println(max_value)
    max_positions = findall(i->(i==max_value), expected_utilities)
    #println(max_positions)
    player_choice_index = rand(max_positions)
    player_choice = player_strategies[player_choice_index]
    #println(player_choice)
    return player_choice
end

#update agent's memory vector
function updateMemory!(player::Agent, opponent::Agent, opponent_choice::Int8, params::SimParams)
    to_push = (opponent.tag, opponent_choice)
    if length(player.memory) == params.memory_length
        popfirst!(player.memory)
    end
    push!(player.memory, to_push)
end

#play the defined game
function playGameOld!(game::Game, params::SimParams, players::Tuple{Agent, Agent})
    player1_memory_length = count(i->(i[1] == players[2].tag), players[1].memory)  #tag specific! (these should both
    player2_memory_length = count(i->(i[1] == players[1].tag), players[2].memory)  #work fine without tags too)
    if player1_memory_length == 0 || rand() <= params.error
        player1_choice = game.strategies[1][rand(1:length(game.strategies[1]))]
    else
        player1_choice = makeChoice(game, players; player_number = Int8(1))
        #println(player1_choice)
    end
    if player2_memory_length == 0 || rand() <= params.error
        player2_choice = game.strategies[2][rand(1:length(game.strategies[2]))]
    else
        player2_choice = makeChoice(game, players; player_number = Int8(2))
        #println(player2_choice)
    end
    #outcome = game.payoff_matrix[player1_choice, player2_choice] #don't need this right now (wealth is not being analyzed)
    #players[1].wealth += outcome[1]
    #players[2].wealth += outcome[2]
    updateMemory!(players[1], players[2], player2_choice, params)
    updateMemory!(players[2], players[1], player1_choice, params)
end