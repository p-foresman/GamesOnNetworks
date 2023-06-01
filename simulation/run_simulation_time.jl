########## This script shows the order of steps to run simulations ###########

## 1: add processess if you want simulations to run in a distributed manner
using Distributed
addprocs(0; exeflags="--project")

## 2: import the main module on all processes
@everywhere using GamesOnNetworks


## 3: initiallize sqlite file with proper schema if it doesn't already exist at the filepath
const db_filepath = "./sqlite/test25.sqlite"
initDataBase(db_filepath)
#NOTE: simulation groups must be created manually. Use insertSimGroup("description") to insert group. Returns the group_id in 'insert_row_id' field.
const sim_group_id = insertSimGroup(db_filepath, "test time data").insert_row_id


## 4: include script that contains all globals for simulation
include("sim_setup.jl")

## 5: run simulation
simulateIterator(game, sim_params_list, graph_params_list; period_cutoff=1000, run_count=1, starting_condition=:fractious, db_filepath=db_filepath, db_store_period=1, db_sim_group_id=sim_group_id) #need to create a new group for each time series simulation. Maybe should just make a simulateTimeSeries()? Ultimately can't use simulationIterator with time series stuff


##6: remove worker cores
if nprocs() > 1
    for id in workers()
        rmprocs(id)
    end
end