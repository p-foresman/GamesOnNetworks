const sim_params_1 = SimParams(number_agents = 10,
                            memory_length = 10,
                            memory_init_state = :fractious,
                            error = 0.1,
                            tag1 = :red,
                            tag2 = :blue,
                            tag1_proportion = 1.0,
                            random_seed = 1234)

const sim_params_2 = SimParams(number_agents = 30,
                            memory_length = 13,
                            memory_init_state = :fractious,
                            error = 0.1,
                            tag1 = :red,
                            tag2 = :blue,
                            tag1_proportion = 1.0,
                            random_seed = 1234)


const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])

const game = Game("Bargaining Game", payoff_matrix)


const graph_params_complete = CompleteParams()
