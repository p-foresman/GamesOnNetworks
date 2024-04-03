const Graph = SimpleGraph{Int}
const AgentSet{N} = SVector{N, Agent}
const Relationship = Graphs.SimpleEdge{Int}
const RelationshipSet{E} = SVector{E, Relationship}
const ComponentRelationshipSets{C} = SVector{C, RelationshipSet}

"""
    GamesOnNetworks.AgentGraph{N, E, C} <: AbstractGraph{Int}

A type extending the Graphs.jl SimpleGraph functionality by adding agents to each vertex.
This is a simpler alternative to MetaGraphs.jl for the purposes of this package.

N = number of vertices,
E = number of edges,
C = number of connected components
"""
struct AgentGraph{N, E, C} <: AbstractGraph{Int}
    graph::Graph
    agents::AgentSet{N}
    edges::RelationshipSet{E} #all edges
    component_edge_sets::ComponentRelationshipSets{C} #edges separated by connected components
    # number_agents::Int
    number_hermits::Int
    
    function AgentGraph(graph::Graph)
        N = nv(graph)
        E = ne(graph)
        agents::SVector{N, Agent} = [Agent("Agent $agent_number") for agent_number in 1:N]
        number_hermits = 0
        for vertex in 1:N #could make graph-type specific multiple dispatch so this only needs to happen for ER and SBM (otherwise num_hermits=0)
            if degree(graph, vertex) == 0
                ishermit!(agents[vertex], true)
                number_hermits += 1
            end
        end
        graph_edges = RelationshipSet{E}(collect(Graphs.edges(graph)))
        component_edge_sets = []
        C = 0
        for component_edge_set in connected_component_edges(graph)
            C += 1
            push!(component_edge_sets, RelationshipSet{length(component_edge_set)}(component_edge_set))
        end
        component_edge_sets = ComponentRelationshipSets{C}(component_edge_sets)
        return new{N, E, C}(graph, agents, graph_edges, component_edge_sets, number_hermits)
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
    component_edge_sets(agent_graph::AgentGraph)

Get all of the connected component edge sets that reside in an AgentGraph instance.
Returns a vector of vectors, each containing the edges in each separated component.
"""
component_edge_sets(agent_graph::AgentGraph) = getfield(agent_graph, :component_edge_sets)

"""
    component_edge_sets(agent_graph::AgentGraph, component_number::Integer)

Get the connected component edge set indexed by component_number in an AgentGraph instance.
Returns a vector of Graphs.SimpleEdge instances.
"""
component_edge_sets(agent_graph::AgentGraph, component_number::Integer) = getindex(component_edge_sets(agent_graph), component_number)

"""
    component_edge_sets(agent_graph::AgentGraph, component_number::Integer, edge_number::Integer)

Get the edge indexed by edge_number in the connected component edge set indexed by component_number in an AgentGraph instance.
Returns a Graphs.SimpleEdge instance.
"""
component_edge_sets(agent_graph::AgentGraph, component_number::Integer, edge_number::Integer) = getindex(component_edge_sets(agent_graph, component_number), edge_number)

"""
    random__component_edge(agent_graph::AgentGraph, component_number::Integer)

Get a random edge/relationship in the component specified by component_number in an AgentGraph instance.
"""
random_component_edge(agent_graph::AgentGraph, component_number::Integer) = rand(component_edge_sets(agent_graph, component_number))

"""
    number_hermits(agent_graph::AgentGraph)

Get the number of hermits (vertecies with degree=0) in an AgentGraph instance.
"""
number_hermits(agent_graph::AgentGraph) = getfield(agent_graph, :number_hermits)


