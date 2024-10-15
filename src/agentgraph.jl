const Graph = SimpleGraph{Int}
const AgentSet{N} = SVector{N, Agent}
const VertexSet{V} = SVector{V, Int}
const Relationship = Graphs.SimpleEdge{Int}
const RelationshipSet{E} = SVector{E, Relationship}

"""
    GamesOnNetworks.AgentGraph{N, E, C} <: AbstractGraph{Int}

A type extending the Graphs.jl SimpleGraph functionality by adding agents to each vertex.
This is a simpler alternative to MetaGraphs.jl for the purposes of this package.

N = number of vertices,
E = number of edges,
C = number of connected components
"""
struct ConnectedComponent{V, E}
    vertices::VertexSet{V}
    # edges::RelationshipSet{E} #can delete for now to save allocations
    matches_per_period::Int

    function ConnectedComponent(vertices::Vector{Int}, edges::Vector{Graphs.SimpleEdge})
        V = length(vertices)
        E = length(edges)
        d = E / possible_edge_count(V)
        matches_per_period = Int(ceil(d * V / 2)) #ceil to ensure at least one match (unless d=0, in which case nothing would happen regardless)
        return new{V, E}(VertexSet{V}(vertices), matches_per_period)
    end
end

const ComponentSet{C} = SVector{C, ConnectedComponent}
const EmptyComponentSet = ComponentSet{0}

vertices(component::ConnectedComponent) = getfield(component, :vertices)
num_vertices(::ConnectedComponent{V, E}) where {V, E} = V
# edges(component::ConnectedComponent) = getfield(component, :edges)
num_edges(::ConnectedComponent{V, E}) where {V, E} = E
# random_edge(component::ConnectedComponent) = rand(edges(component))
matches_per_period(component::ConnectedComponent) = getfield(component, :matches_per_period)


struct AgentGraph{N, E, C} <: AbstractGraph{Int}
    graph::Graph
    agents::AgentSet{N}
    components::ComponentSet{C} #NOTE: different ConnectedComponents will have different V and E static params, meaning that getting a specific component from this set wont be type stable. Doesn't account for a huge change in practice with one component, but could find a way to fix or optimize by not using a component set if there is only one component
    number_hermits::Int #is this necessary?

    # vertices::VertexSet{N}
    # matches_per_period::Int

    
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
        vertex_sets, edge_sets, C = connected_component_sets(graph)
        components = []
        for component_number in 1:C
            push!(components, ConnectedComponent(vertex_sets[component_number], edge_sets[component_number]))
        end

        # d = E / possible_edge_count(N)
        # matches_per_period = Int(ceil(d * N / 2)) #ceil to ensure at least one match (unless d=0, in which case nothing would happen regardless)

        return new{N, E, C}(graph, agents, ComponentSet{C}(components), number_hermits)#, VertexSet{N}(Graphs.vertices(graph)), matches_per_period)
    end
end

##########################################
# AgentGraph Accessors
##########################################


num_vertices(::AgentGraph{N, E, C}) where {N, E, C} = N

num_edges(::AgentGraph{N, E, C}) where {N, E, C} = E

num_components(::AgentGraph{N, E, C}) where {N, E, C} = C

"""
    graph(agentgraph::AgentGraph)

Get the graph (Graphs.SimpleGraph{Int}) defined in an AgentGraph instance.
"""
graph(agentgraph::AgentGraph) = getfield(agentgraph, :graph)

"""
    agents(agentgraph::AgentGraph)

Get all of the agents in an AgentGraph instance.
"""
agents(agentgraph::AgentGraph) = getfield(agentgraph, :agents)

"""
    agents(agentgraph::AgentGraph, agent_number::Integer)

Get the agent indexed by the agent_number in an AgentGraph instance.
"""
agents(agentgraph::AgentGraph, agent_number::Integer) = getindex(agents(agentgraph), agent_number)

# """
#     edges(agentgraph::AgentGraph)

# Get all of the edges/relationships in an AgentGraph instance.
# """
# edges(agentgraph::AgentGraph) = getfield(agentgraph, :edges)

# """
#     edges(agentgraph::AgentGraph, edge_number::Integer)

# Get the edge indexed by the edge_number in an AgentGraph instance.
# """
# edges(agentgraph::AgentGraph, edge_number::Integer) = getindex(edges(agentgraph), edge_number)

# """
#     random_edge(agentgraph::AgentGraph)

# Get a random edge/relationship in an AgentGraph instance.
# """
# random_edge(agentgraph::AgentGraph) = rand(edges(agentgraph))


num_vertices(::VertexSet{V}) where {V} = V

"""
    components(agentgraph::AgentGraph)

Get all of the connected componentd that reside in an AgentGraph instance.
Returns a vector of ConnectedComponent objects.
"""
components(agentgraph::AgentGraph) = getfield(agentgraph, :components)

"""
    components(agentgraph::AgentGraph, component_number::Integer)

Get the ConnectedComponent object indexed by component_number in an AgentGraph instance's 'components' field.
"""
components(agentgraph::AgentGraph, component_number::Integer) = getindex(components(agentgraph), component_number)


# num_edges(::RelationshipSet{E}) where {E} = E


"""
    number_hermits(agentgraph::AgentGraph)

Get the number of hermits (vertecies with degree=0) in an AgentGraph instance.
"""
number_hermits(agentgraph::AgentGraph) = getfield(agentgraph, :number_hermits)


