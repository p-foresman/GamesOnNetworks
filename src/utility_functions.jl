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


# sf2 = scale_free(100, 2)
# sf3 = scale_free(100, 3)
# ba1 = barabasi_albert(100, 1)
# ba2 = barabasi_albert(100, 2)
# ba3 = barabasi_albert(100, 3)
# ba4 = barabasi_albert(100, 4)


# sf4 = scale_free(100000, 3)
