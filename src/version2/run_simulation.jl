# using Distributed
# addprocs(2; exeflags="--project")
using BenchmarkTools
include("simulation.jl")




@btime simGroupIterator(averager=10, use_seed=true, db_store=false)


# sim_params = SimParams(number_agents=10, memory_length=10, memory_init_state=:fractious, error=0.1, tag1=:red, tag2=:blue, tag1_proportion=1.0, random_seed=1234)
# graph = ErdosRenyiParams(1.0)
# @btime simulateTransitionTime(game, sim_params, graph, use_seed=true) #seed could be put into SimParams
# result = pullFromDatabase(1)
# restore = restoreFromDatabase(1)
#df = querySimulationSQL(1)