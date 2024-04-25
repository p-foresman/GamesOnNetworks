# # An extended implementation of Graphs.jl 'static_scale_free' which allows the user to input the ratio of possible edges
# function scale_free(n::Int, α::Float64, m_scaler::Float64)
#     m_possible = (n * (n-1)) / 2
#     m = Int(round(m_scaler * m_possible))
#     return static_scale_free(n, m, α)
# end


possible_edge_count(N::Int) = Int((N * (N-1)) / 2)
edge_density(N::Integer, λ::Real) = λ / (N - 1)
edge_count(N::Integer, d::Float64) = Int(round(d * possible_edge_count(N)))
mean_degree(N::Int, d::Float64) = Int(round((N - 1) * d))

function connected_component_vertices(g::AbstractGraph{T}) where {T}
    return filter(component -> length(component) > 1, connected_components(g))
end

function connected_component_sets(g::AbstractGraph{T}) where {T}
    component_vertex_sets = connected_component_vertices(g)
    # component_edges = fill([], length(components))
    component_count = length(component_vertex_sets)
    component_edge_sets::Vector{Vector{Graphs.SimpleEdge}} = []
    for vertex_set in component_vertex_sets
        edge_set::Vector{Graphs.SimpleEdge} = []
        for edge in Graphs.edges(g)
            if edge.src in vertex_set && edge.dst in vertex_set
                push!(edge_set, edge)
            end
        end
        push!(component_edge_sets, edge_set)
    end
    return component_vertex_sets, component_edge_sets, component_count
end

function connected_component_edges(g::AbstractGraph{T}) where {T}
    return connected_component_sets(g)[2]
end


function erdos_renyi_rg(N::Integer, λ::Real; kwargs...)
    @assert λ <= N - 1 "λ must be <= N - 1"
    num_edges = edge_count(N, edge_density(N, λ))
    return erdos_renyi(N, num_edges; kwargs...) #we can use d or num_edges here (num_edges will be exact while d will slightly change)
end
# NOTE: edge probability == density for ER, so normal erdos_renyi(n, p) function is already in terms of density

"""
    small_world_rg(N::Integer, λ::Real, β::Real; kwargs...)

Constructor that uses the Graphs.watts_strogatz() method where λ = κ.
"""
function small_world_rg(N::Integer, λ::Real, β::Real; kwargs...)
    @assert λ <= N - 1 "λ must be <= N - 1"
    if λ == N - 1
        return complete_graph(N)
    else
        return watts_strogatz(N, Int(round(λ)), β; kwargs...)
    end
end


function scale_free_rg(N::Integer, λ::Real, α::Real; kwargs...)
    @assert λ <= N - 1 "λ must be <= N - 1"
    num_edges = edge_count(N, edge_density(N, λ))
    return static_scale_free(N, num_edges, α; kwargs...)
end


#NOTE: want to take in overall density as well to remain consistent with others (d). The other things fed are probabilities and inform the SBM
function stochastic_block_model_rg(block_sizes::Vector{<:Integer}, λ::Real, in_block_probs::Vector{<:Real}, out_block_prob::Real)
    @assert λ <= sum(block_sizes) - 1 "λ must be <= N - 1, where N = sum(block_sizes)"
    affinity_matrix = Graphs.SimpleGraphs.sbmaffinity(in_block_probs, out_block_prob, block_sizes)
    N = sum(block_sizes)
    num_edges = edge_count(N, edge_density(N, λ))
    return SimpleGraph(N, num_edges, StochasticBlockModel(block_sizes, affinity_matrix))
end