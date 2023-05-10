module GamesOnNetworks

export 
    Game,
    SimParams,
    Agent,
    GraphParams,
    CompleteParams,
    ErdosRenyiParams,
    SmallWorldParams,
    ScaleFreeParams,
    StochasticBlockModelParams,
    LatticeParams,
    SimParams,
    constructSimParamsList,
    initDataBase,
    insertSimGroup,
    collectDBFilesInDirectory,
    simulationIterator,
    simulateTransitionTime,
    simulateIterator, #** these two should be merged with the two above functions eventually
    simulate, #**
    determineAgentBehavior,
    transitionTimesBoxPlot,
    memoryLengthTransitionTimeLinePlot,
    numberAgentsTransitionTimeLinePlot

using
    Graphs,
    MetaGraphs,
    Random,
    StaticArrays,
    DataFrames,
    JSON3,
    SQLite,
    UUIDs,
    Distributed,
    GraphPlot,
    StatsPlots,
    Cairo,
    Fontconfig,
    Statistics,
    Bootstrap

include("types.jl")
include("sql.jl")
include("database_api.jl")
include("functions.jl")
include("construct_params.jl")
include("simulation.jl")
include("plotting.jl")

end