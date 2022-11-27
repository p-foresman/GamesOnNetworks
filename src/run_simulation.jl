using Distributed
const number_cores = 3
addprocs(number_cores; exeflags="--project")
@everywhere using Distributed
# using BenchmarkTools
const db_filepath = "./sqlite/SimulationSaves.sqlite"
@everywhere include("simulation.jl")




simGroupIterator(averager=15, db_store=true, db_sim_group_id=2)
rmprocs(number_cores - (number_cores - 2):number_cores + 1)


# sim_params = SimParams(number_agents=10, memory_length=10, memory_init_state=:fractious, error=0.1, tag1=:red, tag2=:blue, tag1_proportion=1.0, random_seed=1234)
# graph = ErdosRenyiParams(1.0)
# @btime simulateTransitionTime(game, sim_params, graph, use_seed=true) #seed could be put into SimParams
# result = pullFromDatabase(1)
# restore = restoreFromDatabase(1)
#df = querySimulationSQL(1)