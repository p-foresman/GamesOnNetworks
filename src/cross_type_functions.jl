##### multiple dispatch for various graph parameter sets #####
function initGraph(::CompleteParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    graph = complete_graph(number_agents(sim_params))
    agent_graph = AgentGraph(graph)
    setAgentData!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end

function initGraph(graph_params::ErdosRenyiParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    edge_probability = graph_params.λ / number_agents(sim_params)
    graph = nothing
    while true
        graph = erdos_renyi(number_agents(sim_params), edge_probability)
        if ne(graph) >= 1 #simulation will break if graph has no edges
            break
        end
    end
    agent_graph = AgentGraph(graph)
    setAgentData!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end
function initGraph(graph_params::SmallWorldParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    graph = watts_strogatz(number_agents(sim_params), graph_params.κ, graph_params.β)
    agent_graph = AgentGraph(graph)
    setAgentData!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end
function initGraph(graph_params::ScaleFreeParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    m_count = Int(floor(number_agents(sim_params) ^ 1.5)) #this could be better defined
    graph = static_scale_free(number_agents(sim_params), m_count, graph_params.α)
    agent_graph = AgentGraph(graph)
    setAgentData!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end
function initGraph(graph_params::StochasticBlockModelParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    community_size = Int(number_agents(sim_params) / graph_params.communities)
    # println(community_size)
    internal_edge_probability = graph_params.internal_λ / community_size
    internal_edge_probability_vector = Vector{Float64}([])
    sizes_vector = Vector{Int}([])
    for community in 1:graph_params.communities
        push!(internal_edge_probability_vector, internal_edge_probability)
        push!(sizes_vector, community_size)
    end
    external_edge_probability = graph_params.external_λ / number_agents(sim_params)
    affinity_matrix = Graphs.SimpleGraphs.sbmaffinity(internal_edge_probability_vector, external_edge_probability, sizes_vector)
    graph = nothing
    while true
        graph = stochastic_block_model(affinity_matrix, sizes_vector)
        if ne(graph) >= 1
            break
        end
    end
    agent_graph = AgentGraph(graph)
    setAgentData!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end



function setAgentData!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::FractiousState)
    for (vertex, agent) in enumerate(agents(agent_graph))
        #set memory initialization
        if vertex % 2 == 0
            recollection = strategies(game)[1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
        else
            recollection = strategies(game)[3]
        end
        empty!(memory(agent))
        agent.rational_choice = Choice(0)
        agent.choice = Choice(0)
        for _ in 1:memory_length(sim_params)
            push!(memory(agent), recollection)
        end
    end
    return nothing
end

function setAgentData!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::EquityState)
    for (vertex, agent) in enumerate(agents(agent_graph))
        #set memory initialization
        recollection = strategies(game)[2]
        empty!(memory(agent))
        agent.rational_choice = Choice(0)
        agent.choice = Choice(0)
        for _ in 1:memory_length(sim_params)
            push!(memory(agent), recollection)
        end
    end
    return nothing
end

function setAgentData!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::RandomState)
    for (vertex, agent) in enumerate(agents(agent_graph))
        #set memory initialization
        empty!(memory(agent))
        agent.rational_choice = Choice(0)
        agent.choice = Choice(0)
        for _ in 1:memory_length(sim_params)
            push!(memory(agent), random_strategy(game))
        end
    end
    return nothing
end


function resetAgentGraph!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    setAgentData!(agent_graph, game, sim_params, starting_condition)
    return nothing
end

############################ tagged versions (not currently using) ##############################

# function setAgentData!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::FractiousState)
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

# function setAgentData!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::EquityState)
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

# function setAgentData!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::RandomState)
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


function initStoppingCondition!(stopping_condition::EquityPsychological, sim_params::SimParams, agent_graph::AgentGraph)
    stopping_condition.sufficient_equity = (1 - error(sim_params)) * memory_length(sim_params)
    stopping_condition.sufficient_transitioned = number_agents(sim_params) - number_hermits(agent_graph)
    return nothing
end

function initStoppingCondition!(stopping_condition::EquityBehavioral, sim_params::SimParams, agent_graph::AgentGraph)
    stopping_condition.sufficient_transitioned = (1 - error(sim_params)) * (number_agents(sim_params) - number_hermits(agent_graph)) # (1-error) term removes the agents that are expected to choose randomly, attemting to factor out the error
    stopping_condition.period_cutoff = memory_length(sim_params)
    stopping_condition.period_count = 0
    return nothing
end

function initStoppingCondition!(::PeriodCutoff, ::SimParams, ::AgentGraph)
    return nothing
end