const payoff_matrix = [(0, 0) (0, 0) (70, 30);
                        (0, 0) (50, 50) (50, 30);
                        (30, 70) (30, 50) (30, 30)]

const game_list = [Game{3, 3}("Bargaining Game", payoff_matrix)]

game = Game{3, 3}("Bargaining Game", payoff_matrix)

sim_params = SimParams(1000, 10, 0.1, random_seed=1234)

graph_params = ErdosRenyiParams(999.0)

starting = FractiousState()

stopping = EquityBehavioral(2)

m = SimModel(game, sim_params, graph_params, starting, stopping)
