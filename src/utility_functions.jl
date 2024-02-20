# Resets the distributed processes
function resetprocs()
    if nprocs() > 1
        for id in workers()
            rmprocs(id)
        end
    end
end


# An extended implementation of Graphs.jl 'static_scale_free' which allows the user to input the ratio of possible edges
function scale_free(n::Int, α::Float64, m_scaler::Float64)
    m_possible = (n * (n-1)) / 2
    m = Int(round(m_scaler * m_possible))
    return static_scale_free(n, m, α)
end
