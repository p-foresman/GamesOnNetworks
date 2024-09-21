"""
    GamesOnNetworks

Package used to simulate games over network interaction structures.
"""
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
    number_agents,
    memory_length,
    error_rate,
    matches_per_period,
    random_seed,

    graph_params,
    graph_type, #rename to type?
    λ,
    β,
    α,
    blocks,
    p_in,
    p_out,

    starting_condition,
    type, #rename?

    stopping_condition,
    strategy, #rename?
    sufficient_equity,
    sufficient_equity!,
    sufficient_transitioned,
    sufficient_transitioned!,
    period_cutoff,
    period_cutoff!,
    period_count,
    period_count!,
    increment_period_count!,

    # vertices,
    # num_vertices, #these are from the ConnectedComponent struct (should i export?)
    # edges,
    # num_edges,

    agent_graph,
    graph,
    agents,
    # edges, #rename?
    random_edge,
    components,
    num_components,
    # component_vertex_sets,
    # component_edge_sets,
    # random_component_edge,
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
    increment_opponent_strategy_recollection!,
    opponent_strategy_probabilities,
    expected_utilities,
    expected_utilities!,
    increment_expected_utilities!,
    reset_arrays!,

    model_id,
    displayname,
    reset_model!,
    regenerate_model,

    # constructors
    construct_sim_params_list,
    construct_model_list,
    select_and_construct_model,

    #simulation
    simulate,
    simulate_distributed,
    simulation_iterator,

    # determine_agent_behavior, #NOTE: FIX THIS

    #database api
    db_init,
    db_insert_sim_group,
    db_collect_temp,

    #plotting
    transitionTimesBoxPlot,
    memoryLengthTransitionTimeLinePlot,
    numberAgentsTransitionTimeLinePlot,
    timeSeriesPlot,
    multipleTimeSeriesPlot,

    #utility
    resetprocs,

    #graph constructors
    erdos_renyi_rg,
    small_world_rg,
    scale_free_rg,
    stochastic_block_model_rg


using
    Graphs,
    # MetaGraphs,
    Random,
    StaticArrays,
    DataFrames,
    JSON3,
    # SQLite,
    # LibPQ,
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
include("utility.jl")

#extensions of Graphs.jl graph constructors
include("graphs.jl")

#custom types and their methods
include("games.jl")
include("agents.jl")
include("graphparams.jl")
include("simparams.jl")
include("startingconditions.jl")
include("stoppingconditions.jl")
include("agentgraph.jl")
include("preallocatedarrays.jl")

#functions which require a combination of types
include("cross_type_functions.jl")

#simulation functions should go here and model barrier functions should be in the simulation_model.jl file
#basically, make sure to delagate any functions pertaining to individual types to that file, then add
#combined type functions after all in a separate file, then define the SimModel and then the mode function barriers.
#essentially, barriers need to be build from the bottom up ****

#SimModel type and methods
include("simmodel.jl")

#api to sqlite and postgresql functionality
include("database/database_api.jl")

#simulation functions
include("simulation_functions.jl")
include("simulate.jl")

#plotting functions
include("analysis.jl")
include("plotting.jl")

#include default config and configure
include("settings/config.jl")
configure()

end