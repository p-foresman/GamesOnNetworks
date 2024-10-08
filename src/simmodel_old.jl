"""
    SimModel{S1, S2, V, E}

A type which defines the entire model for simulation. Contains Game, SimParams, GraphModel, StartingCondition,
StoppingCondition, AgentGraph, and PreAllocatedArrays.

S1 = row dimension of Game instance
S2 = column dimension of Game instance
V = number of agents/vertices
E = number of relationships/edges
"""
struct SimModel{S1, S2, V, E}
    id::Union{Nothing, Int}
    game::Game{S1, S2}
    simparams::SimParams
    graphmodel::GraphModel
    startingcondition::StartingCondition
    stoppingcondition::StoppingCondition
    agentgraph::AgentGraph{V, E}
    preallocatedarrays::PreAllocatedArrays

    function SimModel(game::Game{S1, S2}, simparams::SimParams, graphmodel::GraphModel, startingcondition::StartingCondition, stoppingcondition::StoppingCondition, id::Union{Nothing, Int} = nothing) where {S1, S2}
        agentgraph = initialize_graph!(graphmodel, game, simparams, startingcondition)
        V = nv(graph(agentgraph))
        E = ne(graph(agentgraph))
        initialize_stopping_condition!(stoppingcondition, simparams, agentgraph)
        preallocatedarrays = PreAllocatedArrays(payoff_matrix(game))
        return new{S1, S2, V, E}(id, game, simparams, graphmodel, startingcondition, stoppingcondition, agentgraph, preallocatedarrays)
    end
    function SimModel(model::SimModel) #used to generate a new model with the same parameters (newly sampled random graph structure)
        return SimModel(game(model), simparams(model), graphmodel(model), startingcondition(model), stoppingcondition(model), id(model))
    end
end


##########################################
# PreAllocatedArrays Accessors
##########################################

"""
    id(model::SimModel)

Get the id of a SimModel instance (primarily for distributed computing purposes).
"""
id(model::SimModel) = getfield(model, :id)

#Game
"""
    game(model::SimModel)

Get the Game instance in the model.
"""
game(model::SimModel) = getfield(model, :game)

"""
    payoff_matrix(game::SimModel)

Get the payoff matrix for the model.
"""
payoff_matrix(model::SimModel) = payoff_matrix(game(model))

"""
    strategies(game::SimModel)

Get the possible strategies that can be played in the model.
"""
strategies(model::SimModel) = strategies(game(model))

"""
    strategies(game::SimModel, player_number::Int)

Get the possible strategies that can be played by the given player number in the model.
"""
strategies(model::SimModel, player_number::Int) = strategies(game(model), player_number)

"""
    random_strategy(game::SimModel)

Get a random strategy from the possible strategies that can be played in the model.
"""
random_strategy(model::SimModel, player_number::Int) = random_strategy(game(model), player_number)


# SimParams
"""
    simparams(model::SimModel)

Get the SimParams instance in the model.
"""
simparams(model::SimModel) = getfield(model, :simparams)

"""
    number_agents(simparams::SimModel)

Get the population size simulation parameter of the model.
"""
number_agents(model::SimModel{S1, S2, V, E}) where {S1, S2, V, E} = V #number_agents(simparams(model)) #NOTE: do this change for all?

"""
    memory_length(simparams::SimModel)

Get the memory length simulation parameter m of the model.
"""
memory_length(model::SimModel) = memory_length(simparams(model))

"""
    error_rate(simparams::SimModel)

Get the error rate simulation parameter ϵ of the model.
"""
error_rate(model::SimModel) = error_rate(simparams(model))

"""
    matches_per_period(simparams::SimModel)

Get the number of matches per period for the model.
"""
matches_per_period(model::SimModel) = matches_per_period(simparams(model))

"""
    random_seed(simparams::SimModel)

Get the random seed for the model.
"""
random_seed(model::SimModel) = random_seed(simparams(model))


# GraphModel
"""
    graphmodel(model::SimModel)

Get the GraphModel instance in the model.
"""
graphmodel(model::SimModel) = getfield(model, :graphmodel)

# """
#     graph_type(graphmodel::SimModel)

# Get the graph type of the model
# """
# graph_type(model::SimModel) = graph_type(graphmodel(model))
# ###add more


#StartingCondition
"""
    startingcondition(model::SimModel)

Get the StartingCondition instance in the model.
"""
startingcondition(model::SimModel) = getfield(model, :startingcondition)


#StoppingCondition
"""
    stoppingcondition(model::SimModel)

Get the StoppingCondition instance in the model.
"""
stoppingcondition(model::SimModel) = getfield(model, :stoppingcondition)


# AgentGraph
"""
    agentgraph(model::SimModel)

Get the AgentGraph instance in the model.
"""
agentgraph(model::SimModel) = getfield(model, :agentgraph)

num_vertices(model::SimModel) = num_vertices(agentgraph(model))

num_edges(model::SimModel) = num_edges(agentgraph(model))

num_components(model::SimModel) = num_components(agentgraph(model))

"""
    graph(model::SimModel)

Get the graph (Graphs.SimpleGraph{Int}) in the model.
"""
graph(model::SimModel) = graph(agentgraph(model))

"""
    agents(model::SimModel)

Get all of the agents in the model.
"""
agents(model::SimModel) = agents(agentgraph(model))

"""
    agents(model::SimModel, agent_number::Integer)

Get the agent indexed by the agent_number in the model.
"""
agents(model::SimModel, agent_number::Integer) = agents(agentgraph(model), agent_number)

"""
    components(model::SimModel)

Get all of the connected componentd that reside in a the model's AgentGraph instance.
Returns a vector of ConnectedComponent objects.
"""
components(model::SimModel) = components(agentgraph(model))

"""
    components(model::SimModel, component_number::Integer)

Get the ConnectedComponent object indexed by component_number in an AgentGraph instance's 'components' field.
"""
components(model::SimModel, component_number::Integer) = components(agentgraph(model), component_number)

# """
#     edges(model::SimModel)

# Get all of the edges/relationships in the model.
# """
# edges(model::SimModel) = edges(agentgraph(model))

# """
#     edges(model::SimModel, edge_number::Integer)

# Get the edge indexed by the edge_number in the model.
# """
# edges(model::SimModel, edge_number::Integer) = edges(agentgraph(model), edge_number)

# """
#     random_edge(model::SimModel)

# Get a random edge/relationship in the model.
# """
# random_edge(model::SimModel) = random_edge(agentgraph(model))

# """
#     component_vertex_sets(model::SimModel)

# Get all of the connected component vertex sets that reside in the model's AgentGraph instance.
# Returns a vector of vectors, each containing the vertices in each separated component.
# """
# component_vertex_sets(model::SimModel) = component_vertex_sets(agentgraph(model))

# """
#     component_vertex_sets(model::SimModel, component_number::Integer)

# Get the connected component vertex set indexed by component_number in the model's AgentGraph instance.
# Returns a vector of Int.
# """
# component_vertex_sets(model::SimModel, component_number::Integer) = component_vertex_sets(agentgraph(model), component_number)

# """
#     component_edge_sets(model::SimModel)

# Get all of the connected component edge sets that reside in the model's AgentGraph instance.
# Returns a vector of vectors, each containing the edges in each separated component.
# """
# component_edge_sets(model::SimModel) = component_edge_sets(agentgraph(model))

# """
#     component_edge_sets(model::SimModel, component_number::Integer)

# Get the connected component edge set indexed by component_number in the model's AgentGraph instance.
# Returns a vector of Graphs.SimpleEdge instances.
# """
# component_edge_sets(model::SimModel, component_number::Integer) = component_edge_sets(agentgraph(model), component_number)

# """
#     component_edge_sets(model::SimModel, component_number::Integer, edge_number::Integer)

# Get the edge indexed by edge_number in the connected component edge set indexed by component_number in the model's AgentGraph instance.
# Returns a Graphs.SimpleEdge instance.
# """
# component_edge_sets(model::SimModel, component_number::Integer, edge_number::Integer) = component_edge_sets(agentgraph(model), component_number, edge_number)

# """
#     random__component_edge(model::SimModel, component_number::Integer)

# Get a random edge/relationship in the component specified by component_number in the model's AgentGraph instance.
# """
# random_component_edge(model::SimModel, component_number::Integer) = rand(component_edge_sets(agentgraph(model), component_number))

"""
    number_hermits(model::SimModel)

Get the number of hermits (vertecies with degree=0) in the model.
"""
number_hermits(model::SimModel) = number_hermits(agentgraph(model))

"""
    reset_agent_graph!(model::SimModel)

Reset the AgentGraph of the model.
"""
reset_agent_graph!(model::SimModel) = agentdata!(agentgraph(model), game(model), simparams(model), startingcondition(model))


#PreAllocatedArrays
"""
    preallocatedarrays(model::SimModel)

Get the PreAllocatedArrays instance in the model.
"""
preallocatedarrays(model::SimModel) = getfield(model, :preallocatedarrays)

"""
    players(model::SimModel)

Get the currently cached players in the model.
"""
players(model::SimModel) = players(preallocatedarrays(model))

"""
    players(model::SimModel, player_number::Integer)

Get the player indexed by player_number currently cached in the model.
"""
players(model::SimModel, player_number::Integer) = players(preallocatedarrays(model), player_number)

"""
    player!(model::SimModel, player_number::Integer, agent::Agent)

Set the player indexed by player_number to the Agent instance agent.
"""
player!(model::SimModel, player_number::Integer, agent::Agent) = player!(preallocatedarrays(model), player_number, agent)

"""
    player!(model::SimModel, player_number::Integer, agent_number::Integer)

Set the player indexed by player_number to the Agent instance indexed by agent_number in the AgentGraph instance.
"""
player!(model::SimModel, player_number::Integer, agent_number::Integer) = player!(preallocatedarrays(model), player_number, agents(model, agent_number))

"""
    set_players!(model::SimModel, component::ConnectedComponent)

Choose a random relationship/edge in the specified component and set players to be the agents that the edge connects.
"""
function set_players!(model::SimModel, component::ConnectedComponent)
    v = rand(vertices(component))
    player!(model, 1, v)
    player!(model, 2, rand(neighbors(graph(model), v)))
    # edge::Graphs.SimpleEdge{Int} = random_edge(component)
    # vertex_list::Vector{Int} = shuffle!([src(edge), dst(edge)]) #NOTE: is the shuffle necessary here?
    # for player_number in 1:2 #NOTE: this will always be 2. Should I just optimize for two player games?
    #     player!(model, player_number, vertex_list[player_number])
    # end
    return nothing
end

#temp for complete_graph
# function set_players!(model::SimModel) #NOTE: this could be better
#     v = rand(Graphs.vertices(graph(model)))
#     player!(model, 1, v)
#     player!(model, 2, rand(neighbors(graph(model), v)))
#     return nothing
# end

"""
    opponent_strategy_recollection(model::SimModel)

Get the currently cached recollections of each player (i.e., the quantity of each strategy that resides in players' memories).
"""
opponent_strategy_recollection(model::SimModel) = opponent_strategy_recollection(preallocatedarrays(model))

"""
    opponent_strategy_recollection(model::SimModel, player_number::Integer)

Get the currently cached recollection of the player indexed by player_number.
"""
opponent_strategy_recollection(model::SimModel, player_number::Integer) = opponent_strategy_recollection(preallocatedarrays(model), player_number)

"""
    opponent_strategy_recollection(model::SimModel, player_number::Integer, index::Integer)

Get the currently cached recollection of a strategy indexed by index of the player indexed by player_number.
"""
opponent_strategy_recollection(model::SimModel, player_number::Integer, index::Integer) = opponent_strategy_recollection(preallocatedarrays(model), player_number, index)

"""
    opponent_strategy_recollection!(model::SimModel, player_number::Integer, index::Integer, value::Int)

Set the recollection of a strategy indexed by index of the player indexed by player_number.
"""
opponent_strategy_recollection!(model::SimModel, player_number::Integer, index::Integer, value::Int) = opponent_strategy_recollection!(preallocatedarrays(model), player_number, index, value)

"""
    increment_opponent_strategy_recollection!(model::SimModel, player_number::Integer, index::Integer, value::Int=1)

Increment the recollection of a strategy indexed by index of the player indexed by player_number by value (defaults to an increment of 1).
"""
increment_opponent_strategy_recollection!(model::SimModel, player_number::Integer, index::Integer, value::Int=1) = increment_opponent_strategy_recollection!(preallocatedarrays(model), player_number, index, value)

"""
    opponent_strategy_probabilities(model::SimModel)

Get the currently cached probabilities that each player's opponent will play each strategy (from recollection).
"""
opponent_strategy_probabilities(model::SimModel) = opponent_strategy_probabilities(preallocatedarrays(model))

"""
    opponent_strategy_probabilities(model::SimModel, player_number::Integer)

Get the currently cached probabilities that the player indexed by player_number's opponent will play each strategy (from recollection).
"""
opponent_strategy_probabilities(model::SimModel, player_number::Integer) = opponent_strategy_probabilities(preallocatedarrays(model), player_number)

"""
    opponent_strategy_probabilities(model::SimModel, player_number::Integer, index::Integer)

Get the currently cached probability that the player indexed by player_number's opponent will play the strategy indexed by index.
"""
opponent_strategy_probabilities(model::SimModel, player_number::Integer, index::Integer) = opponent_strategy_probabilities(preallocatedarrays(model), player_number, index)

"""
    expected_utilities(model::SimModel)

Get the cached expected utilities for playing each strategy for both players.
"""
expected_utilities(model::SimModel) = expected_utilities(preallocatedarrays(model))

"""
    expected_utilities(model::SimModel, player_number::Integer)

Get the cached expected utilities for playing each strategy for the player indexed by player_number.
"""
expected_utilities(model::SimModel, player_number::Integer) = expected_utilities(preallocatedarrays(model), player_number)

"""
    expected_utilities(model::SimModel, player_number::Integer, index::Integer)

Get the cached expected utility for playing the strategy indexed by index for the player indexed by player_number.
"""
expected_utilities(model::SimModel, player_number::Integer, index::Integer) = expected_utilities(preallocatedarrays(model), player_number, index)

"""
    expected_utilities!(model::SimModel, player_number::Integer, index::Integer, value::AbstractFloat)

Set the expected utility for playing the strategy indexed by index for the player indexed by player_number.
"""
expected_utilities!(model::SimModel, player_number::Integer, index::Integer, value::AbstractFloat) = expected_utilities!(preallocatedarrays(model), player_number, index, value)

"""
    increment_expected_utilities!(model::SimModel, player_number::Integer, index::Integer, value::AbstractFloat)

Increment the expected utility for playing the strategy indexed by index for the player indexed by player_number by value.
"""
increment_expected_utilities!(model::SimModel, player_number::Integer, index::Integer, value::AbstractFloat) = increment_expected_utilities!(preallocatedarrays(model), player_number, index, value)

"""
    reset_arrays!(model::SimModel)

Reset the cached arrays in the model's PreAllocatedArrays instance to zeros.
"""
reset_arrays!(model::SimModel) = reset_arrays!(preallocatedarrays(model))

"""
    initialize_graph!(model::SimModel)

Initialize the AgentGraph instance for the model based on parameters of other model components.
"""
initialize_graph!(model::SimModel) = initialize_graph!(graphmodel(model), game(model), simparams(model), startingcondition(model)) #parameter spreading necessary for multiple dispatch

"""
    initialize_stopping_condition!(model::SimModel)

Initialize the stopping condition values for the model based on parameters of the model's SimParams instance and properties of the AgentGraph instance.
"""
initialize_stopping_condition!(model::SimModel) = initialize_stopping_condition!(stoppingcondition(model), simparams(model), agentgraph(model)) #parameter spreading necessary for multiple dispatch

"""
    reset_model!(model::SimModel)

Reset the model to its initial state.
"""
function reset_model!(model::SimModel) #NOTE: THIS DOESNT WORK BECAUSE OF IMMUTABLE STRUCT (could work within individual fields)
    reset_agent_graph!(model)
    initialize_stopping_condition!(model)
    reset_arrays!(model)
    return nothing
end

function regenerate_model(model::SimModel)
    return SimModel(model)
end


function Base.show(model::SimModel)
    println("\n")
    print("Game: ")
    show(game(model))
    print("Graph Model: ")
    show(graphmodel(model))
    print("Sim Params: ")
    show(simparams(model))
    print("Start: ")
    show(startingcondition(model))
    print("Stop: ")
    show(stoppingcondition(model))
end










"""
    construct_model_list(;game_list::Vector{Game} , sim_params_list::Vector{SimParams}, graph_model_list::Vector{<:GraphModel}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, slurm_task_id::Integer=nothing)

Construct a list of models from the combinatorial set of component lists. Used for simulation_iterator() function.
"""
function construct_model_list(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_model_list::Vector{<:GraphModel}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, slurm_task_id::Union{Integer, Nothing}=nothing)
    model_list = Vector{SimModel}([])
    model_number::Int = 1
    for game in game_list
        for simparams in sim_params_list
            for graphmodel in graph_model_list
                for startingcondition in starting_condition_list
                    for stoppingcondition in stopping_condition_list
                        if slurm_task_id === nothing || model_number == slurm_task_id #if slurm_task_id is present, 
                            push!(model_list, SimModel(game, simparams, graphmodel, startingcondition, stoppingcondition, model_number))
                        end
                        model_number += 1
                    end
                end
            end
        end
    end
    return model_list
end

"""
    select_and_construct_model(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_model_list::Vector{<:GraphModel}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, model_number::Integer)

From lists of component parts, select the model indexed by model_number and construct the model. Used for distributed computing on a workload manager like SLURM.
"""
function select_and_construct_model(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_model_list::Vector{<:GraphModel}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, model_number::Integer, print_model::Bool=false)
   #add validation here??  
    current_model_number::Int = 1
    for game in game_list
        for simparams in sim_params_list
            for graphmodel in graph_model_list
                for startingcondition in starting_condition_list
                    for stoppingcondition in stopping_condition_list
                        if current_model_number == model_number
                            if print_model
                                show(game)
                                show(simparams)
                                show(graphmodel)
                                show(startingcondition)
                                show(stoppingcondition)
                                flush(stdout)
                            end
                            return SimModel(game, simparams, graphmodel, startingcondition, stoppingcondition, model_number)
                        end
                        current_model_number += 1
                    end
                end
            end
        end
    end
end