########## This script shows the order of steps to run simulations ###########

using Distributed
addprocs(0; exeflags="--project")
@everywhere using GamesOnNetworks

include("sim_setup.jl")

simulationIterator(game, sim_params_list, graph_params_list; run_count=1, use_seed=true)

# using BenchmarkTools, TimerOutputs
# const times = TimerOutput()

# simulationIterator(run_count=20, db_store=true, db_filepath=db_filepath, db_sim_group_id=1)
# simulationIterator(run_count=1)
