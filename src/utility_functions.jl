# Resets the distributed processes
function resetprocs()
    if nprocs() > 1
        for id in workers()
            rmprocs(id)
        end
    end
end