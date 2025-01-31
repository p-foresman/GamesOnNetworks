using Tar, CodecZlib, GamesOnNetworks

const DIRPATH = ARGS[1]

function main(dirpath::String)
    temppath = joinpath(dirname(dirpath), "temp")

    while true
        try
            #get .tar.gz file
            f = readdir(dirpath; join=true)[1] #could error
            
            #extract it into temp/
            open(GzipDecompressorStream, f) do io
                Tar.extract(io, temppath)
            end

            Database.db_collect_temp(temppath)
            rm(readdir(temppath, join=true)[1])
        catch
            sleep(10)
        end
    end
end

main(DIRPATH)