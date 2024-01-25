"""
SimModel type
"""

struct SimModel{S1, S2, L, N, E}
    id::Union{Nothing, Int64}
    game::Game{S1, S2, L}
    sim_params::SimParams
    graph_params::GraphParams
    starting_condition::StartingCondition
    stopping_condition::StoppingCondition
    agent_graph::AgentGraph{N, E}
    pre_allocated_arrays::PreAllocatedArrays

    function SimModel(game::Game{S1, S2, L}, sim_params::SimParams, graph_params::GraphParams, starting_condition::StartingCondition, stopping_condition::StoppingCondition, id::Union{Nothing, Int64} = nothing) where {S1, S2, L}
        agent_graph = initGraph(graph_params, game, sim_params, starting_condition)
        N = nv(agent_graph.graph)
        E = ne(agent_graph.graph)
        initStoppingCondition!(stopping_condition, sim_params, agent_graph)
        pre_allocated_arrays = PreAllocatedArrays(game.payoff_matrix)
        return new{S1, S2, L, N, E}(id, game, sim_params, graph_params, starting_condition, stopping_condition, agent_graph, pre_allocated_arrays)
    end
end



"""
SimModel function barriers
    -allows for multiple dispatch functionality based on model fields with only the model as an argument
"""

function resetModel!(model::SimModel) #NOTE: THIS DOESNT WORK BECAUSE OF IMMUTABLE STRUCT (could work within individual fields)
    resetAgentGraph!(model.agent_graph, model.game, model.sim_params, model.starting_condition)
    initStoppingCondition!(model.stopping_condition, model.sim_params, model.agent_graph)
    resetArrays!(model.pre_allocated_arrays)
    return nothing
end


function resetArrays!(model::SimModel)
    resetArrays!(model.pre_allocated_arrays)
    return nothing
end


function initGraph(model::SimModel) #look up what this method is called. function barriers?
    initGraph(model.graph_params, model.game, model.sim_params, model.starting_condition)
    return nothing
end

function initStoppingCondition!(model::SimModel)
    initStoppingCondition!(model.stopping_condition, model.sim_params, model.agent_graph)
    return nothing
end




function constructModelList(;game_list::Vector{Game} , sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, slurm_task_id::Integer=nothing)
    model_list = Vector{SimModel}([])
    model_number::Int64 = 1
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

function selectAndConstructModel(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, model_number::Integer)
   #add validation here??  
    current_model_number::Int64 = 1
    for game in game_list
        for sim_params in sim_params_list
            for graph_params in graph_params_list
                for starting_condition in starting_condition_list
                    for stopping_condition in stopping_condition_list
                        if current_model_number == model_number
                            return SimModel(game, sim_params, graph_params, starting_condition, stopping_condition, model_number)
                        end
                        current_model_number += 1
                    end
                end
            end
        end
    end
end