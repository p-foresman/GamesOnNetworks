########## This script shows the order of steps to run simulations ###########

## 1: add processess if you want simulations to run in a distributed manner
using Distributed
addprocs(20; exeflags="--project")

## 2: import the main module on all processes
@everywhere using GamesOnNetworks


## 3: initiallize sqlite file with proper schema if it doesn't already exist at the filepath
const db_filepath = "./sqlite/BehavioralSimulationSaves.sqlite"
# initDataBase(db_filepath)
#NOTE: simulation groups must be created manually. Use insertSimGroup("description") to insert group. Returns the group_id in 'insert_row_id' field.
# const sim_group_id_1 = insertSimGroup(db_filepath, "Population Iteration").insert_row_id
# const sim_group_id_2 = insertSimGroup(db_filepath, "Memory Length Iteration, N=10").insert_row_id
# const sim_group_id_3 = insertSimGroup(db_filepath, "Memory Length Iteration, N=100").insert_row_id

#const sim_group_id_array = [sim_group_id_1, sim_group_id_2, sim_group_id_3]

## 4: include script that contains all globals for simulation
include("sim_setup_slurm.jl")

const slurm_index = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])
const three_index = (slurm_index % 3) == 0 ? 3 : slurm_index % 3
const eight_index = (slurm_index % 8) == 0 ? 8 : slurm_index % 8

#const sim_group_id = sim_group_id_array[three_index]
const sim_params_list = sim_params_list_array[three_index]
const graph_params = [graph_params_list[eight_index]]

## 5: run simulation
# simulationIterator(game, sim_params_list, graph_params_list; run_count=20, stopping_condition=:equity_behavioral, db_filepath=db_filepath, db_sim_group_id=1) # db_filepath=db_filepath, db_sim_group_id=1
simulationIterator(game, sim_params_list, graph_params, starting_condition, stopping_condition; run_count=20, db_filepath=db_filepath, db_sim_group_id=three_index) # db_filepath=db_filepath, db_sim_group_id=1
# simulationIterator(game, sim_params_list_2, graph_params_list, starting_condition, stopping_condition; run_count=20, db_filepath=db_filepath, db_sim_group_id=sim_group_id_2) # db_filepath=db_filepath, db_sim_group_id=1
# simulationIterator(game, sim_params_list_3, graph_params_list, starting_condition, stopping_condition; run_count=20, db_filepath=db_filepath, db_sim_group_id=sim_group_id_3) # db_filepath=db_filepath, db_sim_group_id=1


##6: remove worker cores
if nprocs() > 1
    for id in workers()
        rmprocs(id)
    end
end