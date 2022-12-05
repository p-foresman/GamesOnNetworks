using Distributed
const number_cores = 0
addprocs(number_cores; exeflags="--project") #add some logic to ensure that nprocs is 1 before adding procs
@everywhere using Distributed
using BenchmarkTools, TimerOutputs
@everywhere const db_filepath = "./sqlite/SimulationSaves.sqlite"
@everywhere include("simulation.jl")

# const times = TimerOutput()

# @btime simulationIterator(averager=1, use_seed=false)
# simulationIterator(averager=5, db_store=true, db_filepath=db_filepath, db_sim_group_id=2)
# rmprocs(number_cores - (number_cores - 2):number_cores + 1)


# sim_params = SimParams(number_agents=10, memory_length=10, memory_init_state=:fractious, error=0.1, tag1=:red, tag2=:blue, tag1_proportion=1.0, random_seed=1234)
# graph = ErdosRenyiParams(1.0)
# @btime simulateTransitionTime(game, sim_params, graph, use_seed=true) #seed could be put into SimParams
# result = pullFromDatabase(1)
# restore = restoreFromDatabase(1)
#df = querySimulationSQL(1)