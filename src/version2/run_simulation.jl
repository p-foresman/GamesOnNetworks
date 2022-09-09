include("simulation.jl")

BenchmarkTools.DEFAULT_PARAMETERS.samples = 5

#simIterator(game, params_list, graph_simulations_list, averager=1, seed=false)


params = SimParams(number_agents=10, memory_length=10, memory_init_state=:fractious, error=0.1, tag1=:red, tag2=:blue, tag1_proportion=1.0, random_seed=1234)
graph = Dict(:type => :complete, :plot_label => "Complete", :line_color => :red)
results = simulate(game, params, graph, use_seed=true, db_store=true) #seed could be put into SimParams
#result = pullFromDatabase(1)
# params, game = restoreFromDatabase("Bargaining Game", Dict{Symbol, Any}(:λ => 1.0), 10, 10, 0.1)
#df = querySimulationSQL(1)