"""
    SimModel{S1, S2, L, N, E}

A type which defines the entire model for simulation. Contains Game, SimParams, GraphParams, StartingCondition,
StoppingCondition, AgentGraph, and PreAllocatedArrays.

S1 = row dimension of Game instance
S2 = column dimension of Game instance
L = length of Game payoff_matrix (S1*S2)
N = number of agents/vertices
E = number of relationships/edges
"""
struct SimModel{S1, S2, N, E}
    id::Union{Nothing, Int}
    game::Game{S1, S2}
    sim_params::SimParams
    graph_params::GraphParams
    starting_condition::StartingCondition
    stopping_condition::StoppingCondition
    agent_graph::AgentGraph{N, E}
    pre_allocated_arrays::PreAllocatedArrays

    function SimModel(game::Game{S1, S2}, sim_params::SimParams, graph_params::GraphParams, starting_condition::StartingCondition, stopping_condition::StoppingCondition, id::Union{Nothing, Int} = nothing) where {S1, S2, L}
        agent_graph = initialize_graph!(graph_params, game, sim_params, starting_condition)
        N = nv(graph(agent_graph))
        E = ne(graph(agent_graph))
        initialize_stopping_condition!(stopping_condition, sim_params, agent_graph)
        pre_allocated_arrays = PreAllocatedArrays(payoff_matrix(game))
        return new{S1, S2, N, E}(id, game, sim_params, graph_params, starting_condition, stopping_condition, agent_graph, pre_allocated_arrays)
    end
    function SimModel(model::SimModel) #used to generate a new model with the same parameters (newly sampled random graph structure)
        return SimModel(game(model), sim_params(model), graph_params(model), starting_condition(model), stopping_condition(model), model_id(model))
    end
end


##########################################
# PreAllocatedArrays Accessors
##########################################

"""
    model_id(model::SimModel)

Get the id of a SimModel instance (primarily for distributed computing purposes).
"""
model_id(model::SimModel) = getfield(model, :id)

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
    sim_params(model::SimModel)

Get the SimParams instance in the model.
"""
sim_params(model::SimModel) = getfield(model, :sim_params)

"""
    number_agents(sim_params::SimModel)

Get the population size simulation parameter N of the model.
"""
number_agents(model::SimModel) = number_agents(sim_params(model))

"""
    memory_length(sim_params::SimModel)

Get the memory length simulation parameter m of the model.
"""
memory_length(model::SimModel) = memory_length(sim_params(model))

"""
    error_rate(sim_params::SimModel)

Get the error rate simulation parameter ϵ of the model.
"""
error_rate(model::SimModel) = error_rate(sim_params(model))

"""
    matches_per_period(sim_params::SimModel)

Get the number of matches per period for the model.
"""
matches_per_period(model::SimModel) = matches_per_period(sim_params(model))

"""
    random_seed(sim_params::SimModel)

Get the random seed for the model.
"""
random_seed(model::SimModel) = random_seed(sim_params(model))


# GraphParams
"""
    graph_params(model::SimModel)

Get the GraphParams instance in the model.
"""
graph_params(model::SimModel) = getfield(model, :graph_params)

"""
    graph_type(graph_params::SimModel)

Get the graph type of the model
"""
graph_type(model::SimModel) = graph_type(graph_params(model))
###add more


#StartingCondition
"""
    starting_condition(model::SimModel)

Get the StartingCondition instance in the model.
"""
starting_condition(model::SimModel) = getfield(model, :starting_condition)


#StoppingCondition
"""
    stopping_condition(model::SimModel)

Get the StoppingCondition instance in the model.
"""
stopping_condition(model::SimModel) = getfield(model, :stopping_condition)


# AgentGraph
"""
    agent_graph(model::SimModel)

Get the AgentGraph instance in the model.
"""
agent_graph(model::SimModel) = getfield(model, :agent_graph)

num_vertices(model::SimModel) = num_vertices(agent_graph(model))

num_edges(model::SimModel) = num_edges(agent_graph(model))

num_components(model::SimModel) = num_components(agent_graph(model))

"""
    graph(model::SimModel)

Get the graph (Graphs.SimpleGraph{Int}) in the model.
"""
graph(model::SimModel) = graph(agent_graph(model))

"""
    agents(model::SimModel)

Get all of the agents in the model.
"""
agents(model::SimModel) = agents(agent_graph(model))

"""
    agents(model::SimModel, agent_number::Integer)

Get the agent indexed by the agent_number in the model.
"""
agents(model::SimModel, agent_number::Integer) = agents(agent_graph(model), agent_number)

"""
    components(model::SimModel)

Get all of the connected componentd that reside in a the model's AgentGraph instance.
Returns a vector of ConnectedComponent objects.
"""
components(model::SimModel) = components(agent_graph(model))

"""
    components(model::SimModel, component_number::Integer)

Get the ConnectedComponent object indexed by component_number in an AgentGraph instance's 'components' field.
"""
components(model::SimModel, component_number::Integer) = components(agent_graph(model), component_number)

# """
#     edges(model::SimModel)

# Get all of the edges/relationships in the model.
# """
# edges(model::SimModel) = edges(agent_graph(model))

# """
#     edges(model::SimModel, edge_number::Integer)

# Get the edge indexed by the edge_number in the model.
# """
# edges(model::SimModel, edge_number::Integer) = edges(agent_graph(model), edge_number)

# """
#     random_edge(model::SimModel)

# Get a random edge/relationship in the model.
# """
# random_edge(model::SimModel) = random_edge(agent_graph(model))

# """
#     component_vertex_sets(model::SimModel)

# Get all of the connected component vertex sets that reside in the model's AgentGraph instance.
# Returns a vector of vectors, each containing the vertices in each separated component.
# """
# component_vertex_sets(model::SimModel) = component_vertex_sets(agent_graph(model))

# """
#     component_vertex_sets(model::SimModel, component_number::Integer)

# Get the connected component vertex set indexed by component_number in the model's AgentGraph instance.
# Returns a vector of Int.
# """
# component_vertex_sets(model::SimModel, component_number::Integer) = component_vertex_sets(agent_graph(model), component_number)

# """
#     component_edge_sets(model::SimModel)

# Get all of the connected component edge sets that reside in the model's AgentGraph instance.
# Returns a vector of vectors, each containing the edges in each separated component.
# """
# component_edge_sets(model::SimModel) = component_edge_sets(agent_graph(model))

# """
#     component_edge_sets(model::SimModel, component_number::Integer)

# Get the connected component edge set indexed by component_number in the model's AgentGraph instance.
# Returns a vector of Graphs.SimpleEdge instances.
# """
# component_edge_sets(model::SimModel, component_number::Integer) = component_edge_sets(agent_graph(model), component_number)

# """
#     component_edge_sets(model::SimModel, component_number::Integer, edge_number::Integer)

# Get the edge indexed by edge_number in the connected component edge set indexed by component_number in the model's AgentGraph instance.
# Returns a Graphs.SimpleEdge instance.
# """
# component_edge_sets(model::SimModel, component_number::Integer, edge_number::Integer) = component_edge_sets(agent_graph(model), component_number, edge_number)

# """
#     random__component_edge(model::SimModel, component_number::Integer)

# Get a random edge/relationship in the component specified by component_number in the model's AgentGraph instance.
# """
# random_component_edge(model::SimModel, component_number::Integer) = rand(component_edge_sets(agent_graph(model), component_number))

"""
    number_hermits(model::SimModel)

Get the number of hermits (vertecies with degree=0) in the model.
"""
number_hermits(model::SimModel) = number_hermits(agent_graph(model))

"""
    reset_agent_graph!(model::SimModel)

Reset the AgentGraph of the model.
"""
reset_agent_graph!(model::SimModel) = agentdata!(agent_graph(model), game(model), sim_params(model), starting_condition(model))


#PreAllocatedArrays
"""
    pre_allocated_arrays(model::SimModel)

Get the PreAllocatedArrays instance in the model.
"""
pre_allocated_arrays(model::SimModel) = getfield(model, :pre_allocated_arrays)

"""
    players(model::SimModel)

Get the currently cached players in the model.
"""
players(model::SimModel) = players(pre_allocated_arrays(model))

"""
    players(model::SimModel, player_number::Integer)

Get the player indexed by player_number currently cached in the model.
"""
players(model::SimModel, player_number::Integer) = players(pre_allocated_arrays(model), player_number)

"""
    player!(model::SimModel, player_number::Integer, agent::Agent)

Set the player indexed by player_number to the Agent instance agent.
"""
player!(model::SimModel, player_number::Integer, agent::Agent) = player!(pre_allocated_arrays(model), player_number, agent)

"""
    player!(model::SimModel, player_number::Integer, agent_number::Integer)

Set the player indexed by player_number to the Agent instance indexed by agent_number in the AgentGraph instance.
"""
player!(model::SimModel, player_number::Integer, agent_number::Integer) = player!(pre_allocated_arrays(model), player_number, agents(model, agent_number))

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
opponent_strategy_recollection(model::SimModel) = opponent_strategy_recollection(pre_allocated_arrays(model))

"""
    opponent_strategy_recollection(model::SimModel, player_number::Integer)

Get the currently cached recollection of the player indexed by player_number.
"""
opponent_strategy_recollection(model::SimModel, player_number::Integer) = opponent_strategy_recollection(pre_allocated_arrays(model), player_number)

"""
    opponent_strategy_recollection(model::SimModel, player_number::Integer, index::Integer)

Get the currently cached recollection of a strategy indexed by index of the player indexed by player_number.
"""
opponent_strategy_recollection(model::SimModel, player_number::Integer, index::Integer) = opponent_strategy_recollection(pre_allocated_arrays(model), player_number, index)

"""
    opponent_strategy_recollection!(model::SimModel, player_number::Integer, index::Integer, value::Int)

Set the recollection of a strategy indexed by index of the player indexed by player_number.
"""
opponent_strategy_recollection!(model::SimModel, player_number::Integer, index::Integer, value::Int) = opponent_strategy_recollection!(pre_allocated_arrays(model), player_number, index, value)

"""
    increment_opponent_strategy_recollection!(model::SimModel, player_number::Integer, index::Integer, value::Int=1)

Increment the recollection of a strategy indexed by index of the player indexed by player_number by value (defaults to an increment of 1).
"""
increment_opponent_strategy_recollection!(model::SimModel, player_number::Integer, index::Integer, value::Int=1) = increment_opponent_strategy_recollection!(pre_allocated_arrays(model), player_number, index, value)

"""
    opponent_strategy_probabilities(model::SimModel)

Get the currently cached probabilities that each player's opponent will play each strategy (from recollection).
"""
opponent_strategy_probabilities(model::SimModel) = opponent_strategy_probabilities(pre_allocated_arrays(model))

"""
    opponent_strategy_probabilities(model::SimModel, player_number::Integer)

Get the currently cached probabilities that the player indexed by player_number's opponent will play each strategy (from recollection).
"""
opponent_strategy_probabilities(model::SimModel, player_number::Integer) = opponent_strategy_probabilities(pre_allocated_arrays(model), player_number)

"""
    opponent_strategy_probabilities(model::SimModel, player_number::Integer, index::Integer)

Get the currently cached probability that the player indexed by player_number's opponent will play the strategy indexed by index.
"""
opponent_strategy_probabilities(model::SimModel, player_number::Integer, index::Integer) = opponent_strategy_probabilities(pre_allocated_arrays(model), player_number, index)

"""
    expected_utilities(model::SimModel)

Get the cached expected utilities for playing each strategy for both players.
"""
expected_utilities(model::SimModel) = expected_utilities(pre_allocated_arrays(model))

"""
    expected_utilities(model::SimModel, player_number::Integer)

Get the cached expected utilities for playing each strategy for the player indexed by player_number.
"""
expected_utilities(model::SimModel, player_number::Integer) = expected_utilities(pre_allocated_arrays(model), player_number)

"""
    expected_utilities(model::SimModel, player_number::Integer, index::Integer)

Get the cached expected utility for playing the strategy indexed by index for the player indexed by player_number.
"""
expected_utilities(model::SimModel, player_number::Integer, index::Integer) = expected_utilities(pre_allocated_arrays(model), player_number, index)

"""
    expected_utilities!(model::SimModel, player_number::Integer, index::Integer, value::AbstractFloat)

Set the expected utility for playing the strategy indexed by index for the player indexed by player_number.
"""
expected_utilities!(model::SimModel, player_number::Integer, index::Integer, value::AbstractFloat) = expected_utilities!(pre_allocated_arrays(model), player_number, index, value)

"""
    increment_expected_utilities!(model::SimModel, player_number::Integer, index::Integer, value::AbstractFloat)

Increment the expected utility for playing the strategy indexed by index for the player indexed by player_number by value.
"""
increment_expected_utilities!(model::SimModel, player_number::Integer, index::Integer, value::AbstractFloat) = increment_expected_utilities!(pre_allocated_arrays(model), player_number, index, value)

"""
    reset_arrays!(model::SimModel)

Reset the cached arrays in the model's PreAllocatedArrays instance to zeros.
"""
reset_arrays!(model::SimModel) = reset_arrays!(pre_allocated_arrays(model))

"""
    initialize_graph!(model::SimModel)

Initialize the AgentGraph instance for the model based on parameters of other model components.
"""
initialize_graph!(model::SimModel) = initialize_graph!(graph_params(model), game(model), sim_params(model), starting_condition(model)) #parameter spreading necessary for multiple dispatch

"""
    initialize_stopping_condition!(model::SimModel)

Initialize the stopping condition values for the model based on parameters of the model's SimParams instance and properties of the AgentGraph instance.
"""
initialize_stopping_condition!(model::SimModel) = initialize_stopping_condition!(stopping_condition(model), sim_params(model), agent_graph(model)) #parameter spreading necessary for multiple dispatch

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
    print("Graph Params: ")
    show(graph_params(model))
    print("Sim Params: ")
    show(sim_params(model))
    print("Start: ")
    show(starting_condition(model))
    print("Stop: ")
    show(stopping_condition(model))
end










"""
    construct_model_list(;game_list::Vector{Game} , sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, slurm_task_id::Integer=nothing)

Construct a list of models from the combinatorial set of component lists. Used for simulation_iterator() function.
"""
function construct_model_list(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, slurm_task_id::Union{Integer, Nothing}=nothing)
    model_list = Vector{SimModel}([])
    model_number::Int = 1
    for game in game_list
        for sim_params in sim_params_list
            for graph_params in graph_params_list
                for starting_condition in starting_condition_list
                    for stopping_condition in stopping_condition_list
                        if slurm_task_id === nothing || model_number == slurm_task_id #if slurm_task_id is present, 
                            push!(model_list, SimModel(game, sim_params, graph_params, starting_condition, stopping_condition, model_number))
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
    select_and_construct_model(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, model_number::Integer)

From lists of component parts, select the model indexed by model_number and construct the model. Used for distributed computing on a workload manager like SLURM.
"""
function select_and_construct_model(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, model_number::Integer, print_model::Bool=false)
   #add validation here??  
    current_model_number::Int = 1
    for game in game_list
        for sim_params in sim_params_list
            for graph_params in graph_params_list
                for starting_condition in starting_condition_list
                    for stopping_condition in stopping_condition_list
                        if current_model_number == model_number
                            if print_model
                                show(game)
                                show(sim_params)
                                show(graph_params)
                                show(starting_condition)
                                show(stopping_condition)
                                flush(stdout)
                            end
                            return SimModel(game, sim_params, graph_params, starting_condition, stopping_condition, model_number)
                        end
                        current_model_number += 1
                    end
                end
            end
        end
    end
end