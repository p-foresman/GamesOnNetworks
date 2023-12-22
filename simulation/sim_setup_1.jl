# sim setup for RUN 1 of slurm array runs (for complete graph)
# ARRAY SIZE: 100

const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])

const game_list = [Game{3, 3}("Bargaining Game", payoff_matrix)]


const sim_params_list = constructSimParamsList(
                number_agents_list = [N for N in 10:10:200],
                memory_length_list = [10],
                error_list = [0.05, 0.1]
                )

append!(sim_params_list, constructSimParamsList(
    number_agents_list = [10],
    memory_length_list = [7, 13, 16, 18, 19],
    error_list = [0.05, 0.1]
))

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