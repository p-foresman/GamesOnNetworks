##### multiple dispatch for various graph parameter sets #####
function initGraph(::CompleteParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    graph = complete_graph(sim_params.number_agents)
    agent_graph = AgentGraph(graph)
    setAgentData!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end

function initGraph(graph_params::ErdosRenyiParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    edge_probability = graph_params.λ / sim_params.number_agents
    graph = nothing
    while true
        graph = erdos_renyi(sim_params.number_agents, edge_probability)
        if graph.ne >= 1 #simulation will break if graph has no edges
            break
        end
    end
    agent_graph = AgentGraph(graph)
    setAgentData!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end
function initGraph(graph_params::SmallWorldParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    graph = watts_strogatz(sim_params.number_agents, graph_params.κ, graph_params.β)
    agent_graph = AgentGraph(graph)
    setAgentData!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end
function initGraph(graph_params::ScaleFreeParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    m_count = Int(floor(sim_params.number_agents ^ 1.5)) #this could be better defined
    graph = static_scale_free(sim_params.number_agents, m_count, graph_params.α)
    agent_graph = AgentGraph(graph)
    setAgentData!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end
function initGraph(graph_params::StochasticBlockModelParams, game::Game, sim_params::SimParams, starting_condition::StartingCondition)
    community_size = Int(sim_params.number_agents / graph_params.communities)
    # println(community_size)
    internal_edge_probability = graph_params.internal_λ / community_size
    internal_edge_probability_vector = Vector{Float64}([])
    sizes_vector = Vector{Int}([])
    for community in 1:graph_params.communities
        push!(internal_edge_probability_vector, internal_edge_probability)
        push!(sizes_vector, community_size)
    end
    external_edge_probability = graph_params.external_λ / sim_params.number_agents
    affinity_matrix = Graphs.SimpleGraphs.sbmaffinity(internal_edge_probability_vector, external_edge_probability, sizes_vector)
    graph = nothing
    while true
        graph = stochastic_block_model(affinity_matrix, sizes_vector)
        if graph.ne >= 1
            break
        end
    end
    agent_graph = AgentGraph(graph)
    setAgentData!(agent_graph, game, sim_params, starting_condition)
    return agent_graph
end



function setAgentData!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::FractiousState)
    println("setAgentData running")
    for (vertex, agent) in enumerate(agent_graph.agents)
        #set memory initialization
        if vertex % 2 == 0
            recollection = game.strategies[1][1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
        else
            recollection = game.strategies[1][3]
        end
        empty!(agent.memory)
        println(agent.rational_choice)
        agent.rational_choice = Choice(0)
        agent.choice = Choice(0)
        println(agent.rational_choice)
        for _ in 1:sim_params.memory_length
            push!(agent.memory, recollection)
        end
    end
    return nothing
end

function setAgentData!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::EquityState)
    for (vertex, agent) in enumerate(agent_graph.agents)
        #set memory initialization
        recollection = game.strategies[1][2]
        empty!(agent.memory)
        agent.rational_choice = Choice(0)
        agent.choice = Choice(0)
        for _ in 1:sim_params.memory_length
            push!(agent.memory, recollection)
        end
    end
    return nothing
end

function setAgentData!(agent_graph::AgentGraph, game::Game, sim_params::SimParams, starting_condition::RandomState)
    for (vertex, agent) in enumerate(agent_graph.agents)
        #set memory initialization
        empty!(agent.memory)
        agent.rational_choice = Choice(0)
        agent.choice = Choice(0)
        for _ in 1:sim_params.memory_length
            push!(agent.memory, rand(game.strategies[1]))
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
#             recollection = game.strategies[1][1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
#         else
#             recollection = game.strategies[1][3]
#         end
#         to_push = (agent.tag, recollection)
#         for _ in 1:sim_params.memory_length
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
#         recollection = game.strategies[1][2]
#         to_push = (agent.tag, recollection)
#         for _ in 1:sim_params.memory_length
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
#         for _ in 1:sim_params.memory_length
#             to_push = (agent.tag, rand(game.strategies[1]))
#             push!(agent.memory, to_push)
#         end
#     end
#     return nothing
# end


function initStoppingCondition!(stopping_condition::EquityPsychological, sim_params::SimParams, agent_graph::AgentGraph)
    stopping_condition.sufficient_equity = (1 - sim_params.error) * sim_params.memory_length
    stopping_condition.sufficient_transitioned = sim_params.number_agents - agent_graph.number_hermits
    return nothing
end

function initStoppingCondition!(stopping_condition::EquityBehavioral, sim_params::SimParams, agent_graph::AgentGraph)
    stopping_condition.sufficient_transitioned = (1 - sim_params.error) * (sim_params.number_agents - agent_graph.number_hermits) # (1-error) term removes the agents that are expected to choose randomly, attemting to factor out the error
    stopping_condition.period_cutoff = sim_params.memory_length
    stopping_condition.period_count = 0
    return nothing
end

function initStoppingCondition!(::PeriodCutoff, ::SimParams, ::AgentGraph)
    return nothing
end