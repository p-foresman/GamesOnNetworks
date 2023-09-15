const sim_params_list = constructSimParamsList(
                number_agents_start = 10, #creates iterator for multi-loop simulation
                number_agents_end = 200,
                number_agents_step = 10,
                memory_length_start = 10, #creates iterator for multi-loop simulation
                memory_length_end = 10,
                memory_length_step = 3,
                memory_init_state = :fractious, #specifies initialization state. Choose between :fractious, :equity, and :custom (:custom will initialize from a separate dataframe)
                error_list = [0.05, 0.1], #iterated over for multi-loop simulation
                tag1 = :red,
                tag2 = :blue,
                tag1_proportion = 1.0, #1.0 for effectively "no tags" (all agents get tag1)
                random_seed = 1234 #sets random number generator
                )

const sim_params_list_2 = constructSimParamsList(
                number_agents_start = 10, #creates iterator for multi-loop simulation
                number_agents_end = 10,
                number_agents_step = 10,
                memory_length_start = 10, #creates iterator for multi-loop simulation
                memory_length_end = 19,
                memory_length_step = 3,
                memory_init_state = :fractious, #specifies initialization state. Choose between :fractious, :equity, and :custom (:custom will initialize from a separate dataframe)
                error_list = [0.05, 0.1], #iterated over for multi-loop simulation
                tag1 = :red,
                tag2 = :blue,
                tag1_proportion = 1.0, #1.0 for effectively "no tags" (all agents get tag1)
                random_seed = 1234 #sets random number generator
                )

const sim_params_list_3 = constructSimParamsList(
                number_agents_start = 100, #creates iterator for multi-loop simulation
                number_agents_end = 100,
                number_agents_step = 10,
                memory_length_start = 10, #creates iterator for multi-loop simulation
                memory_length_end = 19,
                memory_length_step = 3,
                memory_init_state = :fractious, #specifies initialization state. Choose between :fractious, :equity, and :custom (:custom will initialize from a separate dataframe)
                error_list = [0.05, 0.1], #iterated over for multi-loop simulation
                tag1 = :red,
                tag2 = :blue,
                tag1_proportion = 1.0, #1.0 for effectively "no tags" (all agents get tag1)
                random_seed = 1234 #sets random number generator
                )
                

################### Define Game Payoff Matrix and Strategies #######################

const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])
#Check "global_StructTypes.jl" file and ensure that the size of this payoff matrix is listed under the "Game type" section

# s1 = size(payoff_matrix, 1)
# s2 = size(payoff_matrix, 2)

#create bargaining game type (players will be slotted in)
const game = Game{3, 3}("Bargaining Game", payoff_matrix) # would game::Game{s1, s2} improve performance?



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
    ErdosRenyiParams(1.0),
    ErdosRenyiParams(5.0),
    SmallWorldParams(4, 0.6),
    ScaleFreeParams(2.0),
    ScaleFreeParams(4.0),
    ScaleFreeParams(8.0),
    StochasticBlockModelParams(2, 5.0, 0.5)
]

const starting_condition = FractiousState(game)
const stopping_condition = EquityBehavioral(game, 2)

const stopping_condition_test = PeriodCutoff(10000)