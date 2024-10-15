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
    startingcondition::StartingCondition
    stoppingcondition::StoppingCondition

    function SimModel(game::Game{S1, S2, L}, simparams::SimParams, graphmodel::GraphModel, startingcondition::StartingCondition, stoppingcondition::StoppingCondition) where {S1, S2, L}
        # initialize_stopping_condition!(stoppingcondition, simparams, agentgraph)
        return new{S1, S2, L}(game, simparams, graphmodel, startingcondition, stoppingcondition)
    end
    # function SimModel(model::SimModel) #used to generate a new model with the same parameters (newly sampled random graph structure)
    #     return SimModel(game(model), simparams(model), graphmodel(model), startingcondition(model), stoppingcondition(model), id(model))
    # end
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