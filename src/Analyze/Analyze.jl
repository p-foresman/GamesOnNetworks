module Analyze

export
    a,
    transitionTimesBoxPlot

import ..Database

using
    Plots,
    GraphPlot,
    StatsPlots,
    Cairo,
    Fontconfig,
    Statistics,
    Bootstrap

include("plotting.jl")
include("analysis.jl")
a = "hiiiii"

end #Analyze