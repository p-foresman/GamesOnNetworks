module GamesOnNetworks

export 
    simulationIterator

using
    Graphs,
    MetaGraphs,
    Random,
    StaticArrays,
    DataFrames,
    JSON3,
    SQLite,
    Distributed

include("types.jl")
include("sql.jl")
include("database_api.jl")
include("setup_params.jl") #could figure out a way to put this outside of module
include("simulation.jl")

end