using Distributed
addprocs(20; exeflags="--project")

@everywhere using GamesOnNetworks

const db_filepath = "./slurm_simulation_saves.sqlite"
# db_init(db_filepath)
# const sim_group_id = db_insert_sim_group("Example Group Description")


const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])


const game_list = [Game{3, 3}("Bargaining Game", payoff_matrix)]


const sim_params_list = construct_sim_params_list(
                number_agents_list = [10], #creates iterator for multi-loop simulation
                memory_length_list = insert!([N for N in 7:3:19], 5, 18), #creates iterator for multi-loop simulation
                error_list = [0.05, 0.1] #iterated over for multi-loop simulation
                )

append!(sim_params_list, construct_sim_params_list(
    number_agents_list = [N for N in 20:10:100], #creates iterator for multi-loop simulation
    memory_length_list = [10], #creates iterator for multi-loop simulation
    error_list = [0.1]
))

append!(sim_params_list, construct_sim_params_list(
    number_agents_list = [N for N in 15:5:50], #creates iterator for multi-loop simulation
    memory_length_list = [10], #creates iterator for multi-loop simulation
    error_list = [0.05]
))

append!(sim_params_list, construct_sim_params_list(
    number_agents_list = [N for N in 10:2:20], #creates iterator for multi-loop simulation
    memory_length_list = [10], #creates iterator for multi-loop simulation
    error_list = [0.02]
))

const graph_params_list = [
    CompleteParams()
]

const starting_condition_list = [FractiousState()]
const stopping_condition_list = [EquityPsychological(2), EquityBehavioral(2)]


const slurm_task_id = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])
const model = select_and_construct_model(game_list=game_list, sim_params_list=sim_params_list, graph_params_list=graph_params_list, starting_condition_list=starting_condition_list, stopping_condition_list=stopping_condition_list, model_number=slurm_task_id)


simulate_distributed(model, db_filepath, run_count=nworkers())

resetprocs()

################### Define Game Payoff Matrix and Strategies #######################