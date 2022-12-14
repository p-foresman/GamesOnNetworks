########## This script shows the order of steps to run simulations ###########

using Distributed
addprocs(0; exeflags="--project")
@everywhere push!(LOAD_PATH, "./src")


# using BenchmarkTools, TimerOutputs
# const times = TimerOutput()


@everywhere using GamesOnNetworks

# simulationIterator(run_count=20, db_store=true, db_filepath=db_filepath, db_sim_group_id=1)
# simulationIterator(run_count=1)
