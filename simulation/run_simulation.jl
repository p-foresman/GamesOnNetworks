########## This script shows the order of steps to run simulations ###########

## 1: add processess if you want simulations to run in a distributed manner
using Distributed
addprocs(4; exeflags="--project")

## 2: import the main module on all processes
@everywhere using GamesOnNetworks


## 3: initiallize sqlite file with proper schema if it doesn't already exist at the filepath
const db_filepath = "./sqlite/SimulationSaves.sqlite"
initDataBase(db_filepath)

## 4: include script that contains all globals for simulation
include("sim_setup.jl")

## 5: run simulation
simulationIterator(game, sim_params_list, graph_params_list; run_count=20, db_store=true, db_filepath=db_filepath, db_sim_group_id=2)




# using BenchmarkTools, TimerOutputs
# const times = TimerOutput()