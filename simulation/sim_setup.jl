################### Define Game Payoff Matrix and Strategies #######################

const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])
#Check "global_StructTypes.jl" file and ensure that the size of this payoff matrix is listed under the "Game type" section

# s1 = size(payoff_matrix, 1)
# s2 = size(payoff_matrix, 2)

#create bargaining game type (players will be slotted in)
const game_list = [Game{3, 3}("Bargaining Game", payoff_matrix)] # would game::Game{s1, s2} improve performance?



const sim_params_list = constructSimParamsList(
                number_agents_list = [N for N in 10:10:200], #creates iterator for multi-loop simulation
                memory_length_list = [10], #creates iterator for multi-loop simulation
                error_list = [0.05, 0.1] #iterated over for multi-loop simulation
                )

append!(sim_params_list, constructSimParamsList(
    number_agents_list = [10], #creates iterator for multi-loop simulation
    memory_length_list = [7, 13, 16, 18, 19], #creates iterator for multi-loop simulation
    error_list = [0.05, 0.1]
))

################### Define Which Graph Types to Iterate Through #######################

#=
Graph types available with relevant type constructors and parameters (structs found in types.jl):
    Complete Graph: CompleteParams()
    Erdos-Renyi Random Graph: ErdosRenyiParams(λ)
    Watts-Strogatz Small-World Network: SmallWorldParams(κ, β)
    Scale-Free Network (currently NOT Barabasi-Albert): ScaleFreeParams(α)
    Stochastic Block Model: StochasticBlockModelParams(communities, internal_λ, external_λ)
=#

const graph_params_list = [
    CompleteParams(),
    # ErdosRenyiParams(1.0),
    # ErdosRenyiParams(2.0),
    # ErdosRenyiParams(3.0),
    # ErdosRenyiParams(4.0),
    # ErdosRenyiParams(5.0),
    # SmallWorldParams(4, 0.6),
    # ScaleFreeParams(2.0),
    # ScaleFreeParams(4.0),
    # ScaleFreeParams(8.0),
    # StochasticBlockModelParams(2, 5.0, 0.5)
]

const starting_condition_list = [FractiousState()]
const stopping_condition_list = [EquityBehavioral(2), EquityPsychological(2)]

# const model = SimModel(game_list[1], sim_params_list[2], graph_params_list[1], starting_condition_list[1], stopping_condition_list[2])