module GamesOnNetworks

export
    #types
    SimModel,
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
    FractiousState,
    EquityState,
    RandomState,
    EquityPsychological,
    EquityBehavioral,
    PeriodCutoff,
    constructSimParamsList,
    constructModelList,
    selectAndConstructModel,
    resetModel!,
    initDB,
    insertSimGroup,
    collectDBFilesInDirectory,
    simulationIterator,
    simulate,
    simulateDistributed,
    # distributedSimulationIterator,
    determineAgentBehavior,
    transitionTimesBoxPlot,
    memoryLengthTransitionTimeLinePlot,
    numberAgentsTransitionTimeLinePlot,
    timeSeriesPlot,

    #utility
    resetprocs

using
    Graphs,
    # MetaGraphs,
    Random,
    StaticArrays,
    DataFrames,
    JSON3,
    SQLite,
    UUIDs,
    Distributed,
    Plots,
    GraphPlot,
    StatsPlots,
    Cairo,
    Fontconfig,
    Statistics,
    Bootstrap,
    DataStructures,
    Memoize,
    TimerOutputs

#basic utility functions
include("utility_functions.jl")

#custom types and their methods
include("games.jl")
include("agents.jl")
include("graph_params.jl")
include("simulation_params.jl")
include("starting_conditions.jl")
include("stopping_conditions.jl")
include("agent_graph.jl")
include("pre_allocated_arrays.jl")

#functions which require a combination of types
include("cross_type_functions.jl")

#simulation functions should go here and model barrier functions should be in the simulation_model.jl file
#basically, make sure to delagate any functions pertaining to individual types to that file, then add
#combined type functions after all in a separate file, then define the SimModel and then the mode function barriers.
#essentially, barriers need to be build from the bottom up ****

#SimModel type and methods/barriers
include("simulation_model.jl")
# include("types.jl") #depreciated

#sql functions and api to sql functions
include("sql.jl")
include("database_api.jl")

#simulation functions
include("simulation_functions.jl")
include("simulation.jl")

#plotting functions
include("plotting.jl")

end