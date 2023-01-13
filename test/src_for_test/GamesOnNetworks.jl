using
    Graphs,
    MetaGraphs,
    Random,
    StaticArrays,
    DataFrames,
    JSON3,
    SQLite,
    Distributed,
    Plots,
    GraphPlot,
    StatsPlots,
    Cairo,
    Fontconfig,
    Statistics,
    TimerOutputs

include("types.jl")
include("sql.jl")
include("database_api.jl")
include("construct_params.jl")
include("simulation.jl")
# include("plotting.jl")

include("test_type_stability_setup.jl")

const times = TimerOutput()

# test = simulateTransitionTime(game, sim_params, graph_params, use_seed=true)

function testIterator(n)
    for i in 1:n
        simulateTransitionTime(game, sim_params, graph_params, use_seed=true)
    end
end