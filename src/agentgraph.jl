const Graph = SimpleGraph{Int}
const AgentSet{N} = SVector{N, Agent}
const Relationship = Graphs.SimpleEdge{Int}
const RelationshipSet{E} = SVector{E, Relationship}

"""
    GamesOnNetworks.AgentGraph{N, E} <: AbstractGraph{Int}

A type extending the Graphs.jl SimpleGraph functionality by adding agents to each vertex.
This is a simpler alternative to MetaGraphs.jl for the purposes of this package.

N = number of vertices,
E = number of edges
"""
struct AgentGraph{N, E} <: AbstractGraph{Int}
    graph::Graph
    agents::AgentSet{N}
    edges::RelationshipSet{E}
    component_edge_sets::Vector{Vector{Graphs.SimpleEdge}} #edit later
    # number_agents::Int
    number_hermits::Int
    
    function AgentGraph(graph::Graph)
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
        graph_edges = RelationshipSet{E}(collect(Graphs.edges(graph)))
        component_edge_sets = connected_component_edges(graph)
        return new{N, E}(graph, agents, graph_edges, component_edge_sets, number_hermits)
    end
end



##########################################
# AgentGraph Accessors
##########################################

"""
    graph(agent_graph::AgentGraph)

Get the graph (Graphs.SimpleGraph{Int}) defined in an AgentGraph instance.
"""
graph(agent_graph::AgentGraph) = getfield(agent_graph, :graph)

"""
    agents(agent_graph::AgentGraph)

Get all of the agents in an AgentGraph instance.
"""
agents(agent_graph::AgentGraph) = getfield(agent_graph, :agents)

"""
    agents(agent_graph::AgentGraph, agent_number::Integer)

Get the agent indexed by the agent_number in an AgentGraph instance.
"""
agents(agent_graph::AgentGraph, agent_number::Integer) = getindex(agents(agent_graph), agent_number)

"""
    edges(agent_graph::AgentGraph)

Get all of the edges/relationships in an AgentGraph instance.
"""
edges(agent_graph::AgentGraph) = getfield(agent_graph, :edges)

"""
    edges(agent_graph::AgentGraph, edge_number::Integer)

Get the edge indexed by the edge_number in an AgentGraph instance.
"""
edges(agent_graph::AgentGraph, edge_number::Integer) = getindex(edges(agent_graph), edge_number)

"""
    random_edge(agent_graph::AgentGraph)

Get a random edge/relationship in an AgentGraph instance.
"""
random_edge(agent_graph::AgentGraph) = rand(edges(agent_graph))

"""
    number_hermits(agent_graph::AgentGraph)

Get the number of hermits (vertecies with degree=0) in an AgentGraph instance.
"""
number_hermits(agent_graph::AgentGraph) = getfield(agent_graph, :number_hermits)


