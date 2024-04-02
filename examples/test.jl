################### Define Game Payoff Matrix and Strategies #######################
using GamesOnNetworks, BenchmarkTools

const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])
#Check "global_StructTypes.jl" file and ensure that the size of this payoff matrix is listed under the "Game type" section

# s1 = size(payoff_matrix, 1)
# s2 = size(payoff_matrix, 2)

#create bargaining game type (players will be slotted in)
const game_list = [Game{3, 3}("Bargaining Game", payoff_matrix)] # would game::Game{s1, s2} improve performance?



# const sim_params_list = constructSimParamsList(
#                 number_agents_list = [N for N in 10:10:200], #creates iterator for multi-loop simulation
#                 memory_length_list = [10], #creates iterator for multi-loop simulation
#                 error_list = [0.05, 0.1] #iterated over for multi-loop simulation
#                 )

# append!(sim_params_list, constructSimParamsList(
#     number_agents_list = [10], #creates iterator for multi-loop simulation
#     memory_length_list = [7, 13, 16, 18, 19], #creates iterator for multi-loop simulation
#     error_list = [0.05, 0.1]
# ))

# ################### Define Which Graph Types to Iterate Through #######################

# #=
# Graph types available with relevant type constructors and parameters (structs found in types.jl):
#     Complete Graph: CompleteParams()
#     Erdos-Renyi Random Graph: ErdosRenyiParams(λ)
#     Watts-Strogatz Small-World Network: SmallWorldParams(κ, β)
#     Scale-Free Network (currently NOT Barabasi-Albert): ScaleFreeParams(α)
#     Stochastic Block Model: StochasticBlockModelParams(communities, internal_λ, external_λ)
# =#

# const graph_params_list = [
#     CompleteParams(),
#     # ErdosRenyiParams(1.0),
#     # ErdosRenyiParams(2.0),
#     # ErdosRenyiParams(3.0),
#     # ErdosRenyiParams(4.0),
#     # ErdosRenyiParams(5.0),
#     # SmallWorldParams(4, 0.6),
#     # ScaleFreeParams(2.0),
#     # ScaleFreeParams(4.0),
#     # ScaleFreeParams(8.0),
#     # StochasticBlockModelParams(2, 5.0, 0.5)
# ]

# const starting_condition_list = [FractiousState()]
# const stopping_condition_list = [EquityBehavioral(2), EquityPsychological(2)]
const c2 = SimModel(game_list[1], SimParams(100, 13, 0.1, random_seed=1234), CompleteParams(), FractiousState(), EquityBehavioral(2))
const er2 = SimModel(game_list[1], SimParams(100, 10, 0.02, random_seed=1234), ErdosRenyiParams(5.0), FractiousState(), EquityBehavioral(2))
const sw2 = SimModel(game_list[1], SimParams(1000, 13, 0.1, random_seed=1234), SmallWorldParams(5.0, 0.01), FractiousState(), EquityBehavioral(2))
const sf22 = SimModel(game_list[1], SimParams(1000, 13, 0.1, random_seed=1234), ScaleFreeParams(5.0, 3), FractiousState(), EquityBehavioral(2))
const sbm2 = SimModel(game_list[1], SimParams(1000, 13, 0.1, random_seed=1234), StochasticBlockModelParams(5.0, 2, 0.7, 0.05), FractiousState(), EquityBehavioral(2))

# const c2 = SimModel(game_list[1], SimParams(1000, 10, 0.1, random_seed=1234), CompleteParams(), FractiousState(), EquityBehavioral(2))

const er10 = SimModel(game_list[1], SimParams(1000, 10, 0.01, random_seed=1234), ErdosRenyiParams(5.0), FractiousState(), EquityBehavioral(2))
const sw100 = SimModel(game_list[1], SimParams(1000, 10, 0.01, random_seed=1234), SmallWorldParams(5.0, 0.0), FractiousState(), EquityBehavioral(2))

const er3 = SimModel(game_list[1], SimParams(100, 10, 0.05, random_seed=1234), ErdosRenyiParams(5.0), FractiousState(), EquityBehavioral(2))
const sw3 = SimModel(game_list[1], SimParams(100, 10, 0.05, random_seed=1234), SmallWorldParams(5.0, 0.01), FractiousState(), EquityBehavioral(2))

const er4 = SimModel(game_list[1], SimParams(100, 10, 0.02, random_seed=1234), ErdosRenyiParams(5.0), FractiousState(), EquityBehavioral(2))
const sw4 = SimModel(game_list[1], SimParams(100, 10, 0.02, random_seed=1234), SmallWorldParams(5.0, 0.01), FractiousState(), EquityBehavioral(2))

const er5 = SimModel(game_list[1], SimParams(100, 10, 0.2, random_seed=1234), ErdosRenyiParams(5.0), FractiousState(), EquityBehavioral(2))

const er8= SimModel(game_list[1], SimParams(100, 10, 0.8, random_seed=1234), ErdosRenyiParams(5.0), FractiousState(), EquityBehavioral(2))

# const model22 = SimModel(game_list[1], SimParams(20, 13, 0.1, random_seed=1235), CompleteParams(), FractiousState(), EquityBehavioral(2))
# const model5 = SimModel(game_list[1], SimParams(20, 13, 0.1, random_seed=1234), CompleteParams(), FractiousState(), EquityPsychological(2))
# const model6 = SimModel(game_list[1], SimParams(20, 13, 0.1, random_seed=1235), CompleteParams(), FractiousState(), EquityPsychological(2))
# const model7 = SimModel(game_list[1], SimParams(20, 13, 0.1, random_seed=1235), CompleteParams(), FractiousState(), EquityBehavioral(2))
# const model3 = SimModel(game_list[1], SimParams(10, 10, 0.1, random_seed=1234), CompleteParams(), FractiousState(), EquityPsychological(2))
# const model9 = SimModel(game_list[1], SimParams(10, 10, 0.1, random_seed=1235), ErdosRenyiParams(1.0), FractiousState(), EquityBehavioral(2))
# const model10 = SimModel(game_list[1], SimParams(10, 10, 0.1, random_seed=1235), ErdosRenyiParams(4.0), FractiousState(), EquityBehavioral(2))
# const model11 = SimModel(game_list[1], SimParams(10, 10, 0.1, random_seed=1235), ErdosRenyiParams(4.0), FractiousState(), EquityBehavioral(2))
# const model12 = SimModel(game_list[1], SimParams(10, 10, 0.1, random_seed=1235), ErdosRenyiParams(3.0), FractiousState(), EquityBehavioral(2))
# const model13 = SimModel(game_list[1], SimParams(10, 10, 0.1, random_seed=1235), ErdosRenyiParams(4.0), FractiousState(), EquityBehavioral(2))
# model14 = SimModel(game_list[1], SimParams(10, 10, 0.1, random_seed=1235), ErdosRenyiParams(4.0), FractiousState(), EquityBehavioral(2))


function test_model(model::SimModel)
    simulate(model, use_seed=true)
    reset_model!(model)
end