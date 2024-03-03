"""
    GamesOnNetworks.initialize_graph(graph_params::GraphParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)

Initialize and return an AgentGraph instance.
"""
function initialize_graph!(::CompleteParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    graph = complete_graph(number_agents(sim_params))
    agent_graph = AgentGraph(graph)
    agentdata!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end

function initialize_graph!(graph_params::ErdosRenyiParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    edge_probability = λ(graph_params) / number_agents(sim_params)
    graph = nothing
    while true
        graph = erdos_renyi(number_agents(sim_params), edge_probability)
        if ne(graph) >= 1 #simulation will break if graph has no edges
            break
        end
    end
    agent_graph = AgentGraph(graph)
    agentdata!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end
function initialize_graph!(graph_params::SmallWorldParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    graph = nothing
    while true
        graph = watts_strogatz(number_agents(sim_params), κ(graph_params), β(graph_params))
        if ne(graph) >= 1
            break
        end
    end
    agent_graph = AgentGraph(graph)
    agentdata!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end
function initialize_graph!(graph_params::ScaleFreeParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    graph = nothing
    while true
        graph = scale_free(number_agents(sim_params), α(graph_params), d(graph_params))
        if ne(graph) >= 1
            break
        end
    end
    agent_graph = AgentGraph(graph)
    agentdata!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end
function initialize_graph!(graph_params::StochasticBlockModelParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    @assert number_agents(sim_params) % communities(graph_params) == 0 "Number of communities must divide number of agents evenly"
    community_size = Int(number_agents(sim_params) / communities(graph_params))
    internal_edge_probability = internal_λ(graph_params) / community_size
    internal_edge_probability_vector = Vector{Float64}([])
    sizes_vector = Vector{Int}([])
    for _ in 1:communities(graph_params)
        push!(internal_edge_probability_vector, internal_edge_probability)
        push!(sizes_vector, community_size)
    end
    external_edge_probability = external_λ(graph_params) / number_agents(sim_params)
    affinity_matrix = Graphs.SimpleGraphs.sbmaffinity(internal_edge_probability_vector, external_edge_probability, sizes_vector)
    graph = nothing
    while true
        graph = stochastic_block_model(affinity_matrix, sizes_vector)
        if ne(graph) >= 1
            break
        end
    end
    agent_graph = AgentGraph(graph)
    agentdata!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end


"""
    agentdata!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, ::StoppingCondition)

Initialize the agent data for an AgentGraph instance based on the StoppingCondition concrete type.
"""
function agentdata!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, ::FractiousState)
    for (vertex, agent) in enumerate(agents(agent_graph))
        #set memory initialization
        if vertex % 2 == 0
            recollection = strategies(game)[1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
        else
            recollection = strategies(game)[3]
        end
        empty!(memory(agent))
        rational_choice!(agent, Choice(0))
        choice!(agent, Choice(0))
        for _ in 1:memory_length(sim_params)
            push!(memory(agent), recollection)
        end
    end
    return nothing
end

function agentdata!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, ::EquityState)
    for agent in agents(agent_graph)
        #set memory initialization
        recollection = strategies(game)[2]
        empty!(memory(agent))
        rational_choice!(agent, Choice(0))
        choice!(agent, Choice(0))
        for _ in 1:memory_length(sim_params)
            push!(memory(agent), recollection)
        end
    end
    return nothing
end

function agentdata!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, ::RandomState)
    for agent in agents(agent_graph)
        #set memory initialization
        empty!(memory(agent))
        rational_choice!(agent, Choice(0))
        choice!(agent, Choice(0))
        for _ in 1:memory_length(sim_params)
            push!(memory(agent), random_strategy(game))
        end
    end
    return nothing
end



############################ tagged versions (not currently using) ##############################

# function agentdata!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::FractiousState)
#     for (vertex, agent) in enumerate(agent_graph.agents)
#         if sim_params.tags
#             if rand() <= sim_params.tag1_proportion
#                 agent.tag = sim_params.tag1
#             else
#                 agent.tag = sim_params.tag2
#             end
#         end

#         #set memory initialization
#         #NOTE: tag system needs to change when tags are implemented!!
#         if vertex % 2 == 0
#             recollection = strategies(game)[1][1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
#         else
#             recollection = strategies(game)[1][3]
#         end
#         to_push = (agent.tag, recollection)
#         for _ in 1:memory_length(sim_params)
#             push!(agent.memory, to_push)
#         end
#     end
#     return nothing
# end

# function agentdata!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::EquityState)
#     for (vertex, agent) in enumerate(agent_graph.agents)
#         if rand() <= sim_params.tag1_proportion
#             agent.tag = sim_params.tag1
#         else
#             agent.tag = sim_params.tag2
#         end

#         #set memory initialization
#         #NOTE: tag system needs to change when tags are implemented!!
#         recollection = strategies(game)[1][2]
#         to_push = (agent.tag, recollection)
#         for _ in 1:memory_length(sim_params)
#             push!(agent.memory, to_push)
#         end
#     end
#     return nothing
# end

# function agentdata!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::RandomState)
#     for (vertex, agent) in enumerate(agent_graph.agents)
#         if rand() <= sim_params.tag1_proportion
#             agent.tag = sim_params.tag1
#         else
#             agent.tag = sim_params.tag2
#         end

#         #set memory initialization
#         #NOTE: tag system needs to change when tags are implemented!!
#         for _ in 1:memory_length(sim_params)
#             to_push = (agent.tag, rand(strategies(game)[1]))
#             push!(agent.memory, to_push)
#         end
#     end
#     return nothing
# end

"""
    initialize_stopping_condition!(stopping_condition::StoppingCondition, sim_params::SimParams, agent_graph::AgentGraph)

Initialize the stopping condition for a model.
"""
function initialize_stopping_condition!(stopping_condition::EquityPsychological, sim_params::SimParams, agent_graph::AgentGraph)
    sufficient_equity!(stopping_condition, (1 - error_rate(sim_params)) * memory_length(sim_params))
    sufficient_transitioned!(stopping_condition, Float64(number_agents(sim_params) - number_hermits(agent_graph)))
    return nothing
end

function initialize_stopping_condition!(stopping_condition::EquityBehavioral, sim_params::SimParams, agent_graph::AgentGraph)
    sufficient_transitioned!(stopping_condition, (1 - error_rate(sim_params)) * (number_agents(sim_params) - number_hermits(agent_graph))) # (1-error) term removes the agents that are expected to choose randomly, attemting to factor out the error
    period_cutoff!(stopping_condition, memory_length(sim_params))
    period_count!(stopping_condition, 0)
    return nothing
end

function initialize_stopping_condition!(::PeriodCutoff, ::SimParams, ::AgentGraph)
    return nothing
end