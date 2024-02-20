module GamesOnNetworks

export
    # types
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
    SimParams,
    FractiousState,
    EquityState,
    RandomState,
    EquityPsychological,
    EquityBehavioral,
    PeriodCutoff,

    # accessors
    game,
    payoff_matrix,
    strategies,
    random_strategy,

    sim_params,
    number_agent,
    memory_length,
    error_rate,
    matches_per_period,

    graph_params,
    graph_type,
    λ,
    κ,
    β,
    α,
    d,
    communities,
    internal_λ,
    external_λ,

    starting_condition,

    stopping_condition,

    agent_graph,
    graph,
    agents,
    edges, #rename?
    random_edge,
    number_hermits,

    ishermit, #these accessors only implemented for Agent, should they be implemented for SimModel too?
    memory,
    rational_choice,
    rational_choice!,
    choice,
    choice!,

    pre_allocated_arrays,
    players,
    player!,
    set_players!,
    opponent_strategy_recollection,
    opponent_strategy_recollection!,
    opponent_strategy_probabilities,
    expected_utilities,
    reset_arrays!,


    # constructors
    construct_sim_params_list,
    construct_model_list,
    select_and_construct_model,
    reset_model!,

    #simulation
    simulate,
    simulate_distributed,
    simulation_iterator,

    determineAgentBehavior, #NOTE: FIX THIS
    displayname,

    #database api
    initDB,
    insertSimGroup,
    collectDBFilesInDirectory,

    #plotting
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
    # Memoize,
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