module GON

export
    # types
    SimModel,
    SimModels,
    Game,
    SimParams,
    Agent,
    GraphModel,
    CompleteModel,
    ErdosRenyiModel,
    SmallWorldModel,
    ScaleFreeModel,
    StochasticBlockModel,
    State, #should this be exported?
    AgentGraph, #should this be exported?
    # StartingCondition,
    # FractiousState,
    # EquityState,
    # RandomState,
    # StoppingCondition,
    # EquityPsychological,
    # EquityBehavioral,
    # PeriodCutoff,

    # accessors
    game,
    payoff_matrix,
    size,
    strategies,
    random_strategy,

    graphmodel,
    # graph_type, #rename to type?
    λ,
    β,
    α,
    blocks,
    p_in,
    p_out,

    simparams,
    number_agents,
    memory_length,
    error_rate,
    matches_per_period,
    random_seed,
    UserVariables,
    user_variables,
    set_user_variable!,
    @startingcondition,
    @stoppingcondition,
    starting_condition_fn_str,
    stopping_condition_fn_str,

    # startingcondition,
    type, #rename?

    # stoppingcondition,
    # strategy, #rename?
    # sufficient_equity,
    # sufficient_equity!,
    # sufficient_transitioned,
    # sufficient_transitioned!,
    # period_cutoff,
    # period_cutoff!,
    # period_count,
    # period_count!,
    # increment_period_count!,

    count_strategy,

    period,


    # agentgraph,
    # graph,
    agents,
    # # edges, #rename?
    # random_edge,
    # components,
    # num_components,
    # # component_vertex_sets,
    # # component_edge_sets,
    # # random_component_edge,
    number_hermits,

    ishermit, #these accessors only implemented for Agent, should they be implemented for SimModel too?
    memory,
    # rational_choice,
    # rational_choice!,
    # choice,
    # choice!,

    # preallocatedarrays,
    # players,
    # player!,
    # set_players!,
    # opponent_strategy_recollection,
    # opponent_strategy_recollection!,
    # increment_opponent_strategy_recollection!,
    # opponent_strategy_probabilities,
    # expected_utilities,
    # expected_utilities!,
    # increment_expected_utilities!,
    # reset_arrays!,

    # period,
    # period!,
    # increment_period,

    graph,
    displayname,
    # reset_model!,
    # regenerate_model,

    # constructors
    construct_sim_params_list,
    construct_model_list,
    select_and_construct_model,

    #NOTE: make Generators submodule
    ModelGenerator,
    ErdosRenyiModelGenerator,
    SmallWorldModelGenerator,
    ScaleFreeModelGenerator,
    StochasticBlockModelGenerator

import ..GraphsExt
    
using
    StaticArrays,
    Random,
    Distributed,
    JSON3

include("games.jl")
include("simparams.jl")
include("interactionmodels.jl")
include("agents.jl")
include("agentgraph.jl")
include("preallocatedarrays.jl")
include("simmodel.jl")
include("state.jl")
include("structtypes.jl")
include("generators.jl")

end #GON