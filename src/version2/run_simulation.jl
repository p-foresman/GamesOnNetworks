include("simulation.jl")

#  BenchmarkTools.DEFAULT_PARAMETERS.samples = 5

# simIterator(game, sim_params_list, graph_simulations_list, averager=20, use_seed=false, db_store=true, db_grouping_id=1)


sim_params = SimParams(number_agents=10, memory_length=10, memory_init_state=:fractious, error=0.1, tag1=:red, tag2=:blue, tag1_proportion=1.0, random_seed=1234)
graph = ErdosRenyiParams(1.0)
results = simulateTransitionTime(game, sim_params, graph, use_seed=true, db_store=true) #seed could be put into SimParams
# result = pullFromDatabase(1)
# restore = restoreFromDatabase(1)
#df = querySimulationSQL(1)