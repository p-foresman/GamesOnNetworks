const Graph = SimpleGraph{Int}
const AgentSet{N} = SVector{N, Agent}
const Relationship = Graphs.SimpleEdge{Int}
const RelationshipSet{E} = SVector{E, Relationship}

struct AgentGraph{N, E} #a simpler replacement for MetaGraphs
    graph::Graph
    agents::AgentSet{N}
    edges::RelationshipSet{E}
    # number_agents::Int
    number_hermits::Int
    
    function AgentGraph(graph::SimpleGraph{Int})
        N = nv(graph)
        E = ne(graph)
        agents::SVector{N, Agent} = [Agent("Agent $agent_number") for agent_number in 1:N]
        number_hermits = 0
        for vertex in 1:N #could make graph-type specific multiple dispatch so this only needs to happen for ER and SBM (otherwise num_hermits=0)
            if degree(graph, vertex) == 0
                agents[vertex].is_hermit = true
                number_hermits += 1
            end
        end
        graph_edges = SVector{E, Graphs.SimpleEdge{Int}}(collect(Graphs.edges(graph)))
        return new{N, E}(graph, agents, graph_edges, number_hermits)
    end
end

"""
AgentGraph Accessors
"""
graph(agent_graph::AgentGraph) = agent_graph.graph
agents(agent_graph::AgentGraph) = agent_graph.agents
agent(agent_graph::AgentGraph, agent_number::Integer) = agents(agent_graph)[agent_number]
edges(agent_graph::AgentGraph) = agent_graph.edges
edge(agent_graph::AgentGraph, edge_number::Integer) = edges(agent_graph)[edge_number]
random_edge(agent_graph::AgentGraph) = rand(edges(agent_graph))
number_hermits(agent_graph::AgentGraph) = agent_graph.number_hermits

# function resetAgentGraph!(agent_graph::AgentGraph)
#     for agent in agent_graph.agents
#         resetAgent!(agent)
#     end
#     return nothing
# end


