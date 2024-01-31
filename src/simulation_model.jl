"""
SimModel type
"""

struct SimModel{S1, S2, L, N, E}
    id::Union{Nothing, Int}
    game::Game{S1, S2, L}
    sim_params::SimParams
    graph_params::GraphParams
    starting_condition::StartingCondition
    stopping_condition::StoppingCondition
    agent_graph::AgentGraph{N, E}
    pre_allocated_arrays::PreAllocatedArrays

    function SimModel(game::Game{S1, S2, L}, sim_params::SimParams, graph_params::GraphParams, starting_condition::StartingCondition, stopping_condition::StoppingCondition, id::Union{Nothing, Int} = nothing) where {S1, S2, L}
        agent_graph = initGraph(graph_params, game, sim_params, starting_condition)
        N = nv(agent_graph.graph)
        E = ne(agent_graph.graph)
        initStoppingCondition!(stopping_condition, sim_params, agent_graph)
        pre_allocated_arrays = PreAllocatedArrays(game.payoff_matrix)
        return new{S1, S2, L, N, E}(id, game, sim_params, graph_params, starting_condition, stopping_condition, agent_graph, pre_allocated_arrays)
    end
end


"""
SimModel Accessors
"""
# Game
game(model::SimModel) = model.game
# name(game::Game) = game.name
payoff_matrix(model::SimModel) = payoff_matrix(game(model))
strategies(model::SimModel) = strategies(game(model))
random_strategy(model::SimModel) = random_strategy(game(model))

# SimParams
sim_params(model::SimModel) = model.sim_params
number_agents(model::SimModel) = number_agents(sim_params(model))
memory_length(model::SimModel) = memory_length(sim_params(model))
error(model::SimModel) = error(sim_params(model))

# GraphParams
graph_params(model::SimModel) = model.graph_params
graph_type(model::SimModel) = graph_type(graph_params(model))
###add more

#StartingCondition


#StoppingCondition


# AgentGraph
agent_graph(model::SimModel) = model.agent_graph
graph(model::SimModel) = graph(agent_graph(model))
agents(model::SimModel) = agents(agent_graph(model))
agent(model::SimModel, agent_number::Integer) = agent(agent_graph(model), agent_number)
edges(model::SimModel) = edges(agent_graph(model))
edge(model::SimModel, edge_number::Integer) = edge(agent_graph(model), edge_number)
random_edge(model::SimModel) = random_edge(agent_graph(model))
number_hermits(model::SimModel) = number_hermits(agent_graph(model))

#PreAllocatedArrays
pre_allocated_arrays(model::SimModel) = model.pre_allocated_arrays
players(model::SimModel) = players(pre_allocated_arrays(model))
player(model::SimModel, player_number::Integer) = player(pre_allocated_arrays(model), player_number)
setplayer!(model::SimModel, player_number::Integer, agent::Agent) = setplayer!(pre_allocated_arrays(model), player_number, agent)
setplayer!(model::SimModel, player_number::Integer, agent_number::Integer) = setplayer!(pre_allocated_arrays(model), player_number, agent(model, agent_number))
function setplayers!(model::SimModel)
    edge::Graphs.SimpleEdge{Int} = random_edge(model)
    vertex_list::Vector{Int} = shuffle!([src(edge), dst(edge)]) #NOTE: is the shuffle necessary here?
    for player_number in 1:2 #NOTE: this will always be 2. Should I just optimize for two player games?
        setplayer!(model, player_number, vertex_list[player_number])
    end
    return nothing
end
#add accessors here for opponent_strategy_recollection_containers, etc?
opponent_strategy_recollection(model::SimModel, player_number::Integer) = opponent_strategy_recollection(pre_allocated_arrays(model), player_number)
opponent_strategy_probabilities(model::SimModel, player_number::Integer) = opponent_strategy_probabilities(pre_allocated_arrays(model), player_number)
expected_utilities(model::SimModel, player_number::Integer) = expected_utilities(pre_allocated_arrays(model), player_number)


"""
SimModel function barriers
    -allows for multiple dispatch functionality based on model fields with only the model as an argument
"""
function printModel(model::SimModel) #should override show() instead for pretty printing
    println("\n")
    println(model.game.name)
    println(displayName(model.graph_params))
    print("Number of agents: $(model.sim_params.number_agents), ")
    print("Memory length: $(model.sim_params.memory_length), ")
    println("Error: $(model.sim_params.error)")
    print("Start: $(model.starting_condition.name), ")
    println("Stop: $(model.stopping_condition.name)\n")
end

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

function selectAndConstructModel(;game_list::Vector{<:Game} , sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, starting_condition_list::Vector{<:StartingCondition}, stopping_condition_list::Vector{<:StoppingCondition}, model_number::Integer)
   #add validation here??  
    current_model_number::Int = 1
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