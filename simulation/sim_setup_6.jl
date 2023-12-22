# sim setup for RUN 6 of slurm array runs (for ER graph with λ=2.0)
# ARRAY SIZE: 92

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
    memory_length_list = [13, 16, 19],
    error_list = [0.05, 0.1]
))

const graph_params_list = [
    ErdosRenyiParams(5.0)
]

const starting_condition_list = [FractiousState()]
const stopping_condition_list = [EquityBehavioral(2), EquityPsychological(2)]