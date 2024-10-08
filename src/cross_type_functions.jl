"""
    GamesOnNetworks.initialize_graph(graphmodel::GraphModel, game::Game, simparams::SimParams, startingcondition::StartingCondition)

Initialize and return an AgentGraph instance.
"""
function initialize_graph!(::CompleteModel, game::Game, simparams::SimParams, startingcondition::StartingCondition)
    graph = complete_graph(number_agents(simparams))
    agentgraph = AgentGraph(graph)
    agentdata!(agentgraph, game, simparams, startingcondition)
    return agentgraph
end

function initialize_graph!(graphmodel::ErdosRenyiModel, game::Game, simparams::SimParams, startingcondition::StartingCondition)
    graph::Graphs.SimpleGraphs.SimpleGraph{Int} = erdos_renyi_rg(number_agents(simparams), λ(graphmodel))
    while true
        if ne(graph) >= 1 #NOTE: we aren't considering graphs with no edges (obviously). Does it even make sense to consider graphs with more than one component?
            break
        end
        graph = erdos_renyi_rg(number_agents(simparams), λ(graphmodel))
    end
    agentgraph = AgentGraph(graph)
    agentdata!(agentgraph, game, simparams, startingcondition)
    return agentgraph
end
function initialize_graph!(graphmodel::SmallWorldModel, game::Game, simparams::SimParams, startingcondition::StartingCondition)
    graph::Graphs.SimpleGraphs.SimpleGraph{Int} = small_world_rg(number_agents(simparams), λ(graphmodel), β(graphmodel))
    while true
        if ne(graph) >= 1
            break
        end
        graph = small_world_rg(number_agents(simparams), λ(graphmodel), β(graphmodel))
    end
    agentgraph = AgentGraph(graph)
    agentdata!(agentgraph, game, simparams, startingcondition)
    return agentgraph
end
function initialize_graph!(graphmodel::ScaleFreeModel, game::Game, simparams::SimParams, startingcondition::StartingCondition)
    graph::Graphs.SimpleGraphs.SimpleGraph{Int} = scale_free_rg(number_agents(simparams), λ(graphmodel), α(graphmodel))
    while true
        if ne(graph) >= 1
            break
        end
        graph = scale_free_rg(number_agents(simparams), λ(graphmodel), α(graphmodel))
    end
    agentgraph = AgentGraph(graph)
    agentdata!(agentgraph, game, simparams, startingcondition)
    return agentgraph
end
function initialize_graph!(graphmodel::StochasticBlockModel, game::Game, simparams::SimParams, startingcondition::StartingCondition)
    @assert number_agents(simparams) % blocks(graphmodel) == 0 "Number of blocks must divide number of agents evenly"
    block_size = Int(number_agents(simparams) / blocks(graphmodel))
    p_in_vector = Vector{Float64}([])
    block_sizes_vector = Vector{Int}([])
    for _ in 1:blocks(graphmodel)
        push!(p_in_vector, p_in(graphmodel))
        push!(block_sizes_vector, block_size)
    end
    graph::Graphs.SimpleGraphs.SimpleGraph{Int} = stochastic_block_model_rg(block_sizes_vector, λ(graphmodel), p_in_vector, p_out(graphmodel))
    while true
        if ne(graph) >= 1
            break
        end
        graph = stochastic_block_model_rg(block_sizes_vector, λ(graphmodel), p_in_vector, p_out(graphmodel))
    end
    agentgraph = AgentGraph(graph)
    agentdata!(agentgraph, game, simparams, startingcondition)
    return agentgraph
end


"""
    agentdata!(agentgraph::AgentGraph, game::Game, simparams::SimParams, ::StoppingCondition)

Initialize the agent data for an AgentGraph instance based on the StoppingCondition concrete type.
"""
function agentdata!(agentgraph::AgentGraph, game::Game, simparams::SimParams, ::FractiousState)
    for (vertex, agent) in enumerate(agents(agentgraph))
        #set memory initialization
        if vertex % 2 == 0
            recollection = strategies(game, 1)[1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
        else
            recollection = strategies(game, 1)[3]
        end
        empty!(memory(agent))
        rational_choice!(agent, Choice(0))
        choice!(agent, Choice(0))
        for _ in 1:memory_length(simparams)
            push!(memory(agent), recollection)
        end
    end
    return nothing
end

function agentdata!(agentgraph::AgentGraph, game::Game, simparams::SimParams, ::EquityState)
    for agent in agents(agentgraph)
        #set memory initialization
        recollection = strategies(game, 1)[2]
        empty!(memory(agent))
        rational_choice!(agent, Choice(0))
        choice!(agent, Choice(0))
        for _ in 1:memory_length(simparams)
            push!(memory(agent), recollection)
        end
    end
    return nothing
end

function agentdata!(agentgraph::AgentGraph, game::Game, simparams::SimParams, ::RandomState)
    for agent in agents(agentgraph)
        #set memory initialization
        empty!(memory(agent))
        rational_choice!(agent, Choice(0))
        choice!(agent, Choice(0))
        for _ in 1:memory_length(simparams)
            push!(memory(agent), random_strategy(game, 1))
        end
    end
    return nothing
end



############################ tagged versions (not currently using) ##############################

# function agentdata!(agentgraph::AgentGraph, game::Game, simparams::SimParams, startingcondition::FractiousState)
#     for (vertex, agent) in enumerate(agentgraph.agents)
#         if simparams.tags
#             if rand() <= simparams.tag1_proportion
#                 agent.tag = simparams.tag1
#             else
#                 agent.tag = simparams.tag2
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
#         for _ in 1:memory_length(simparams)
#             push!(agent.memory, to_push)
#         end
#     end
#     return nothing
# end

# function agentdata!(agentgraph::AgentGraph, game::Game, simparams::SimParams, startingcondition::EquityState)
#     for (vertex, agent) in enumerate(agentgraph.agents)
#         if rand() <= simparams.tag1_proportion
#             agent.tag = simparams.tag1
#         else
#             agent.tag = simparams.tag2
#         end

#         #set memory initialization
#         #NOTE: tag system needs to change when tags are implemented!!
#         recollection = strategies(game)[1][2]
#         to_push = (agent.tag, recollection)
#         for _ in 1:memory_length(simparams)
#             push!(agent.memory, to_push)
#         end
#     end
#     return nothing
# end

# function agentdata!(agentgraph::AgentGraph, game::Game, simparams::SimParams, startingcondition::RandomState)
#     for (vertex, agent) in enumerate(agentgraph.agents)
#         if rand() <= simparams.tag1_proportion
#             agent.tag = simparams.tag1
#         else
#             agent.tag = simparams.tag2
#         end

#         #set memory initialization
#         #NOTE: tag system needs to change when tags are implemented!!
#         for _ in 1:memory_length(simparams)
#             to_push = (agent.tag, rand(strategies(game)[1]))
#             push!(agent.memory, to_push)
#         end
#     end
#     return nothing
# end

"""
    initialize_stopping_condition!(stoppingcondition::StoppingCondition, simparams::SimParams, agentgraph::AgentGraph)

Initialize the stopping condition for a model.
"""
function initialize_stopping_condition!(stoppingcondition::EquityPsychological, simparams::SimParams, agentgraph::AgentGraph)
    sufficient_equity!(stoppingcondition, (1 - error_rate(simparams)) * memory_length(simparams))
    sufficient_transitioned!(stoppingcondition, Float64(number_agents(simparams) - number_hermits(agentgraph)))
    return nothing
end

function initialize_stopping_condition!(stoppingcondition::EquityBehavioral, simparams::SimParams, agentgraph::AgentGraph)
    sufficient_transitioned!(stoppingcondition, (1 - error_rate(simparams)) * (number_agents(simparams) - number_hermits(agentgraph))) # (1-error) term removes the agents that are expected to choose randomly, attemting to factor out the error
    period_cutoff!(stoppingcondition, memory_length(simparams))
    period_count!(stoppingcondition, 0)
    return nothing
end

function initialize_stopping_condition!(::PeriodCutoff, ::SimParams, ::AgentGraph)
    return nothing
end