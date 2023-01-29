########## This script shows the order of steps to run simulations ###########

## 1: add processess if you want simulations to run in a distributed manner
using Distributed
addprocs(5) # exeflags="--project"

## 2: import the main module on all processes
@everywhere using GamesOnNetworks


## 3: initiallize sqlite file with proper schema if it doesn't already exist at the filepath
const db_filepath = "/home/fores2/saves/SlurmSimulationSaves.sqlite"
# initDataBase(db_filepath)
#NOTE: simulation groups must be created manually. Use insertSimGroup("description") to insert group. Returns the group_id in 'insert_row_id' field.
# const sim_group_id = insertSimGroup("description").insert_row_id


## 4: include script that contains all globals for simulation
include("sim_setup_slurm.jl")

## 5: run simulation
simulationIterator(game, sim_params_list, graph_params_list; run_count=1, db_filepath=db_filepath, db_sim_group_id=2)


for id in workers()
    rmprocs(id)
end