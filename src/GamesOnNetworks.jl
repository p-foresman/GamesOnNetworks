module GamesOnNetworks

export 
    Game,
    Agent,
    GraphParams,
    CompleteParams,
    ErdosRenyiParams,
    SmallWorldParams,
    ScaleFreeParams,
    StochasticBlockModelParams,
    LatticeParams,
    constructSimParamsList,
    simulationIterator,
    simulateTransitionTime,
    transitionTimesBoxPlot

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
    Statistics

include("types.jl")
include("sql.jl")
include("database_api.jl")
include("setup_params.jl") #could figure out a way to put this outside of module
include("simulation.jl")
include("plotting.jl")

end