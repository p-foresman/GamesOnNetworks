using Distributed
addprocs(5; exeflags="--project")

@everywhere using GamesOnNetworks

const db_filepath = "./sqlite/slurm_simulation_saves.sqlite"
# db_init(db_filepath)
# const sim_group_id = db_insert_sim_group("Example Group Description")


const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])


const game_list = [Game{3, 3}("Bargaining Game", payoff_matrix)]


const sim_params_list = construct_sim_params_list(
                number_agents_list = [1000],
                memory_length_list = [10],
                error_list = [0.1, 0.2]
                )

const graph_params_list = [
    ErdosRenyiParams(3.0),
    ErdosRenyiParams(5.0),
    ErdosRenyiParams(10.0),
    ErdosRenyiParams(50.0),
    ErdosRenyiParams(100.0),
    SmallWorldParams(3.0, 0.0),
    SmallWorldParams(5.0, 0.0),
    SmallWorldParams(10.0, 0.0),
    SmallWorldParams(50.0, 0.0),
    SmallWorldParams(100.0, 0.0),
    SmallWorldParams(3.0, 0.01),
    SmallWorldParams(5.0, 0.01),
    SmallWorldParams(10.0, 0.01),
    SmallWorldParams(50.0, 0.01),
    SmallWorldParams(100.0, 0.01),
    SmallWorldParams(3.0, 0.05),
    SmallWorldParams(5.0, 0.05),
    SmallWorldParams(10.0, 0.05),
    SmallWorldParams(50.0, 0.05),
    SmallWorldParams(100.0, 0.05),
    SmallWorldParams(3.0, 0.1),
    SmallWorldParams(5.0, 0.1),
    SmallWorldParams(10.0, 0.1),
    SmallWorldParams(50.0, 0.1),
    SmallWorldParams(100.0, 0.1),
    SmallWorldParams(3.0, 1.0),
    SmallWorldParams(5.0, 1.0),
    SmallWorldParams(10.0, 1.0),
    SmallWorldParams(50.0, 1.0),
    SmallWorldParams(100.0, 1.0),
    ScaleFreeParams(3.0, 2),
    ScaleFreeParams(5.0, 2),
    ScaleFreeParams(10.0, 2),
    ScaleFreeParams(50.0, 2),
    ScaleFreeParams(100.0, 2),
    ScaleFreeParams(3.0, 3),
    ScaleFreeParams(5.0, 3),
    ScaleFreeParams(10.0, 3),
    ScaleFreeParams(50.0, 3),
    ScaleFreeParams(100.0, 3),
    ScaleFreeParams(3.0, 4),
    ScaleFreeParams(5.0, 4),
    ScaleFreeParams(10.0, 4),
    ScaleFreeParams(50.0, 4),
    ScaleFreeParams(100.0, 4),
    ScaleFreeParams(3.0, 100),
    ScaleFreeParams(5.0, 100),
    ScaleFreeParams(10.0, 100),
    ScaleFreeParams(50.0, 100),
    ScaleFreeParams(100.0, 100),
    StochasticBlockModelParams(3.0, 2, 1.0, 0.005),
    StochasticBlockModelParams(5.0, 2, 1.0, 0.005),
    StochasticBlockModelParams(10.0, 2, 1.0, 0.005),
    StochasticBlockModelParams(50.0, 2, 1.0, 0.005),
    StochasticBlockModelParams(100.0, 2, 1.0, 0.005),
    StochasticBlockModelParams(3.0, 2, 0.75, 0.005),
    StochasticBlockModelParams(5.0, 2, 0.75, 0.005),
    StochasticBlockModelParams(10.0, 2, 0.75, 0.005),
    StochasticBlockModelParams(50.0, 2, 0.75, 0.005),
    StochasticBlockModelParams(100.0, 2, 0.75, 0.005),
    StochasticBlockModelParams(3.0, 2, 0.5, 0.005),
    StochasticBlockModelParams(5.0, 2, 0.5, 0.005),
    StochasticBlockModelParams(10.0, 2, 0.5, 0.005),
    StochasticBlockModelParams(50.0, 2, 0.5, 0.005),
    StochasticBlockModelParams(100.0, 2, 0.5, 0.005),
    StochasticBlockModelParams(3.0, 2, 0.25, 0.005),
    StochasticBlockModelParams(5.0, 2, 0.25, 0.005),
    StochasticBlockModelParams(10.0, 2, 0.25, 0.005),
    StochasticBlockModelParams(50.0, 2, 0.25, 0.005),
    StochasticBlockModelParams(100.0, 2, 0.25, 0.005),
    StochasticBlockModelParams(3.0, 2, 0.005, 0.005),
    StochasticBlockModelParams(5.0, 2, 0.005, 0.005),
    StochasticBlockModelParams(10.0, 2, 0.005, 0.005),
    StochasticBlockModelParams(50.0, 2, 0.005, 0.005),
    StochasticBlockModelParams(100.0, 2, 0.005, 0.005),
]

const starting_condition_list = [FractiousState()]
const stopping_condition_list = [EquityBehavioral(2)]


# const model_list = construct_model_list(game_list=game_list, sim_params_list=sim_params_list, graph_params_list=graph_params_list, starting_condition_list=starting_condition_list, stopping_condition_list=stopping_condition_list)


function simulate_a_bunch(game_list, sim_params_list, graph_params_list, starting_condition_list, stopping_condition_list, db_filepath)
    sim_count = length(game_list) * length(sim_params_list) * length(graph_params_list) * length(starting_condition_list) * length(stopping_condition_list)
    for sim_number in 1:sim_count
            simulate_distributed(select_and_construct_model(game_list=game_list,
                                                            sim_params_list=sim_params_list,
                                                            graph_params_list=graph_params_list,
                                                            starting_condition_list=starting_condition_list,
                                                            stopping_condition_list=stopping_condition_list,
                                                            model_number=sim_number),
                                db_filepath,
                                run_count=nworkers())
    end
end

simulate_a_bunch(game_list, sim_params_list, graph_params_list, starting_condition_list, stopping_condition_list, db_filepath)

# simulation_iterator(model_list, db_filepath, run_count=nworkers())

resetprocs()

################### Define Game Payoff Matrix and Strategies #######################