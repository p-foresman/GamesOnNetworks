"""
    SimModel{S1, S2, V, E}

A type which defines the entire model for simulation. Contains Game, SimParams, GraphModel, StartingCondition,
StoppingCondition, AgentGraph, and PreAllocatedArrays.

S1 = row dimension of Game instance
S2 = column dimension of Game instance
V = number of agents/vertices
E = number of relationships/edges
"""
struct SimModel{S1, S2, L}
    # id::Union{Nothing, Int}
    game::Game{S1, S2, L}
    simparams::SimParams
    graphmodel::GraphModel
    # startingcondition::StartingCondition
    # stoppingcondition::StoppingCondition
    graph::GraphsExt.Graph #the specific graph structure should be specified within a model

    function SimModel(game::Game{S1, S2, L}, simparams::SimParams, graphmodel::GraphModel) where {S1, S2, L}
        graph::GraphsExt.Graph = generate_graph(graphmodel, simparams)
        return new{S1, S2, L}(game, simparams, graphmodel, graph)
    end
    function SimModel(game::Game{S1, S2, L}, simparams::SimParams, graphmodel::GraphModel, graph::GraphsExt.Graph) where {S1, S2, L}
        return new{S1, S2, L}(game, simparams, graphmodel, graph)
    end
    function SimModel(game::Game{S1, S2, L}, simparams::SimParams, graphmodel::GraphModel, graph_adj_matrix::Matrix) where {S1, S2, L}
        graph = GraphsExt.Graph(graph_adj_matrix)
        return new{S1, S2, L}(game, simparams, graphmodel, graph)
    end
    function SimModel(game::Game{S1, S2, L}, simparams::SimParams, graphmodel::GraphModel, graph_adj_matrix_str::String) where {S1, S2, L}
        graph = GraphsExt.Graph(graph_adj_matrix_str)
        return new{S1, S2, L}(game, simparams, graphmodel, graph)
    end
    # function SimModel(model::SimModel) #used to generate a new model with the same parameters (newly sampled random graph structure)
    #     return SimModel(game(model), simparams(model), graphmodel(model), startingcondition(model), stoppingcondition(model), id(model))
    # end
end

function SimModels(game::Game, simparams::SimParams, graphmodel::GraphModel; count::Int)
    return fill(SimModel(game, simparams, graphmodel), count)
end


##########################################
# PreAllocatedArrays Accessors
##########################################

# """
#     id(model::SimModel)

# Get the id of a SimModel instance (primarily for distributed computing purposes).
# """
# id(model::SimModel) = getfield(model, :id)

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
number_agents(model::SimModel) = number_agents(simparams(model)) #NOTE: do this change for all?
# number_agents(model::SimModel{S1, S2, V, E}) where {S1, S2, V, E} = V #number_agents(simparams(model)) #NOTE: do this change for all?

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

# """
#     matches_per_period(simparams::SimModel)

# Get the number of matches per period for the model.
# """
# matches_per_period(model::SimModel) = matches_per_period(simparams(model))

"""
    random_seed(simparams::SimModel)

Get the random seed for the model.
"""
random_seed(model::SimModel) = random_seed(simparams(model))


"""
    starting_condition_fn_str(model::SimModel)

Get the 'starting_condition_fn_str' SimParams field.
"""
starting_condition_fn_str(model::SimModel) = starting_condition_fn_str(simparams(model))

"""
    starting_condition_fn(model::SimModel)

Get the user-defined starting condition function which correlates to the String stored in the 'starting_condition_fn_str' SimParams field.
"""
starting_condition_fn(model::SimModel) = starting_condition_fn(simparams(model))

"""
    starting_condition_fn_call(model::SimModel, agentgraph::AgentGraph)

Call the user-defined starting condition function which correlates to the String stored in the 'starting_condition_fn_str' SimParams field.
"""
starting_condition_fn_call(model::SimModel, agentgraph::AgentGraph) = starting_condition_fn(model)(model, agentgraph)


"""
    stopping_condition_fn_str(model::SimModel)

Get the 'stopping_condition_fn_str' SimParams field.
"""
stopping_condition_fn_str(model::SimModel) = stopping_condition_fn_str(simparams(model))

"""
    stopping_condition_fn(model::SimModel)

Get the user-defined stopping condition function which correlates to the String stored in the 'stopping_condition_fn' SimParams field.
"""
stopping_condition_fn(model::SimModel) = stopping_condition_fn(simparams(model))

"""
    get_enclosed_stopping_condition_fn(model::SimModel)

Call the user-defined stopping condition function which correlates to the String stored in the 'starting_condition_fn_str' SimParams field to get the enclosed function.
"""
get_enclosed_stopping_condition_fn(model::SimModel) = stopping_condition_fn(model)(model) #NOTE: this closure method can probably be eliminated



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
# """
#     startingcondition(model::SimModel)

# Get the StartingCondition instance in the model.
# """
# startingcondition(model::SimModel) = getfield(model, :startingcondition)


# #StoppingCondition
# """
#     stoppingcondition(model::SimModel)

# Get the StoppingCondition instance in the model.
# """
# stoppingcondition(model::SimModel) = getfield(model, :stoppingcondition)

"""
    graph(model::SimModel)

Get the graph associated with a SimModel instance.
"""
graph(model::SimModel) = getfield(model, :graph)

"""
    number_hermits(model::SimModel)

Get the number of hermits (vertecies with degree=0) in the graph of a SimModel instance.
"""
number_hermits(model::SimModel) = number_hermits(graph(model))


#SimModel constructor barriers (used to initialize state components from model)

function AgentGraph(model::SimModel)
    agentgraph::AgentGraph = AgentGraph(graph(model))
    # initialize_agent_data!(agentgraph, game(model), simparams(model), startingcondition(model))
    starting_condition_fn_call(model, agentgraph) #get the user-defined starting condition function and use it to initialize the AgentGraph instance
    return agentgraph
end


"""
    adjacency_matrix_str(model::SimModel)

Get the adjacency matrix in a string for the graph of the given SimModel
"""
adjacency_matrix_str(model::SimModel) = GraphsExt.adjacency_matrix_str(graph(model))


PreAllocatedArrays(model::SimModel) = PreAllocatedArrays(game(model))











function Base.show(model::SimModel)
    println("\n")
    print("Game: ")
    show(game(model))
    print("Graph Model: ")
    show(graphmodel(model))
    print("Sim Params: ")
    show(simparams(model))
    # print("Start: ")
    # show(simparams(model).startingcondition)
    # println()
    # print("Stop: ")
    # show(simparams(model).stoppingcondition)
    # println()
end










"""
    construct_model_list(;game_list::Vector{Game} , sim_params_list::Vector{SimParams}, graph_model_list::Vector{<:GraphModel}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, slurm_task_id::Integer=nothing)

Construct a list of models from the combinatorial set of component lists. Used for simulation_iterator() function.
"""
function construct_model_list(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_model_list::Vector{<:GraphModel}, slurm_task_id::Union{Integer, Nothing}=nothing)
    model_list = Vector{SimModel}([])
    model_number::Int = 1
    for game in game_list
        for simparams in sim_params_list
            for graphmodel in graph_model_list
                if slurm_task_id === nothing || model_number == slurm_task_id #if slurm_task_id is present, 
                    push!(model_list, SimModel(game, simparams, graphmodel, model_number))
                end
                model_number += 1
            end
        end
    end
    return model_list
end

"""
    select_and_construct_model(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_model_list::Vector{<:GraphModel}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, model_number::Integer)

From lists of component parts, select the model indexed by model_number and construct the model. Used for distributed computing on a workload manager like SLURM.
"""
function select_and_construct_model(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_model_list::Vector{<:GraphModel}, model_number::Integer, print_model::Bool=false)
   #add validation here??  
    current_model_number::Int = 1
    for game in game_list
        for simparams in sim_params_list
            for graphmodel in graph_model_list
                if current_model_number == model_number
                    if print_model
                        show(game)
                        show(simparams)
                        show(graphmodel)
                        flush(stdout)
                    end
                    return SimModel(game, simparams, graphmodel, model_number)
                end
                current_model_number += 1
            end
        end
    end
end