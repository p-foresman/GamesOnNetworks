function resetprocs()
    if nprocs() > 1
        for id in workers()
            rmprocs(id)
        end
    end
end


function scale_free(n::Int, α::Int; m_scaler::Float64 = 0.5)
    m_possible = (n * (n-1)) / 2
    m = Int(round(m_scaler * m_possible))
    println(m)
    return static_scale_free(n, m, α)
end


function plot_degree_distribution(g)
    hist = degree_histogram(g)
    total_vertices = nv(g)
    normalized_hist = Dict()
    for (degree, num_vertices) in hist
        normalized_hist[degree] = num_vertices/total_vertices
        # append!(x, degree)
        # append!(y, num_vertices/total_vertices)
    end
    return plot(normalized_hist)
end

function fit_degree_dist(D, g::SimpleGraph{Int})
    sample_points = degree(g)
    return fit(D, sample_points)
end

function plot_fitted_degree_dist(D, g::SimpleGraph{Int})
    nv = Graphs.nv(g)
    return plot(D, x_lims=[0, nv])
end


# sf2 = scale_free(100, 2)
# sf3 = scale_free(100, 3)
# ba1 = barabasi_albert(100, 1)
# ba2 = barabasi_albert(100, 2)
# ba3 = barabasi_albert(100, 3)
# ba4 = barabasi_albert(100, 4)


# sf4 = scale_free(100000, 3)
