########## This script shows the order of steps to run simulations ###########

## 1: add processess if you want simulations to run in a distributed manner
using Distributed
addprocs(20; exeflags="--project") #defines the run count

## 2: import the main module on all processes
@everywhere using GamesOnNetworks


## 3: initiallize sqlite file with proper schema if it doesn't already exist at the filepath
const db_filepath = "./GamesOnNetworksSimulationSaves.sqlite"
#initDataBase(db_filepath)
#NOTE: simulation groups must be created manually. Use insertSimGroup("description") to insert group. Returns the group_id in 'insert_row_id' field.
# const sim_group_id = insertSimGroup(db_filepath, "TESTER").insert_row_id


## 4: include script that contains all globals for simulation
include("sim_setup_1.jl")

#select and construct model based on slurm array task id
const slurm_task_id = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])
const model = selectAndConstructModel(game_list=game_list, sim_params_list=sim_params_list, graph_params_list=graph_params_list, starting_condition_list=starting_condition_list, stopping_condition_list=stopping_condition_list, model_number=slurm_task_id)

## 5: run simulation
simulateDistributed(model, db_filepath, run_count=nworkers())



##6: remove worker cores
if nprocs() > 1
    for id in workers()
        rmprocs(id)
    end
end