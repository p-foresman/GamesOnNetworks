const Graph = SimpleGraph{Int64}
const AgentSet{N} = SVector{N, Agent}
const Relationship = Graphs.SimpleEdge{Int64}
const RelationshipSet{E} = SVector{E, Relationship}

struct AgentGraph{N, E} #a simpler replacement for MetaGraphs
    graph::Graph
    agents::AgentSet{N}
    edges::RelationshipSet{E}
    # number_agents::Int64
    number_hermits::Int64
    
    function AgentGraph(graph::SimpleGraph{Int64})
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
        graph_edges = SVector{E, Graphs.SimpleEdge{Int64}}(collect(edges(graph)))
        return new{N, E}(graph, agents, graph_edges, number_hermits)
    end
end


# function resetAgentGraph!(agent_graph::AgentGraph)
#     for agent in agent_graph.agents
#         resetAgent!(agent)
#     end
#     return nothing
# end


