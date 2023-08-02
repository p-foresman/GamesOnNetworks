########## This script shows the order of steps to run simulations ###########

## 1: add processess if you want simulations to run in a distributed manner
using Distributed
addprocs(20; exeflags="--project")

## 2: import the main module on all processes
@everywhere using GamesOnNetworks


## 3: initiallize sqlite file with proper schema if it doesn't already exist at the filepath
const db_filepath = "./BehavioralSimulationSaves_50.sqlite"
# initDataBase(db_filepath)
#NOTE: simulation groups must be created manually. Use insertSimGroup("description") to insert group. Returns the group_id in 'insert_row_id' field.
# const sim_group_id_1 = insertSimGroup(db_filepath, "Population Iteration").insert_row_id
# const sim_group_id_2 = insertSimGroup(db_filepath, "Memory Length Iteration, N=10").insert_row_id
#const sim_group_id_3 = insertSimGroup(db_filepath, "Memory Length Iteration, N=100").insert_row_id
# const sim_group_id = 4 # insertSimGroup(db_filepath, "Memory Length Iteration, N=50").insert_row_id


#const sim_group_id_array = [sim_group_id_1, sim_group_id_2, sim_group_id_3]

## 4: include script that contains all globals for simulation
const sim_params_list = constructSimParamsList(
                number_agents_start = 50, #creates iterator for multi-loop simulation
                number_agents_end = 50,
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

const game = Game{3, 3}("Bargaining Game", payoff_matrix)

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

# const slurm_index = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])
# const three_index = (slurm_index % 3) == 0 ? 3 : slurm_index % 3
# const eight_index = (slurm_index % 8) == 0 ? 8 : slurm_index % 8

# const sim_group_id = sim_group_id_array[three_index]
# const sim_params_list = sim_params_list_array[three_index]
# const graph_params = [graph_params_list[eight_index]]

## 5: run simulation
distributedSimulationIterator(game, sim_params_list, graph_params_list, starting_condition, stopping_condition; run_count=20, db_filepath=db_filepath, db_sim_group_id=4) # db_filepath=db_filepath, db_sim_group_id=1


##6: remove worker cores
if nprocs() > 1
    for id in workers()
        rmprocs(id)
    end
end