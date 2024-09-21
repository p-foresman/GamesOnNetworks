# type alias for a function parameter being a specified type OR nothing (used a lot)
const Maybe{T} = Union{T, Nothing}


# Resets the distributed processes
function resetprocs()
    if nprocs() > 1
        for id in workers()
            rmprocs(id)
        end
    end
end