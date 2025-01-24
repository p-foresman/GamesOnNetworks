module Analyze

export
    a,
    transitionTimesBoxPlot

import
    ..Database,
    ..GamesOnNetworks.SETTINGS,
    ..GraphsExt

using
    Plots,
    GraphPlot,
    StatsPlots,
    Cairo,
    Fontconfig,
    Statistics,
    Bootstrap,
    ColorSchemes

include("plotting.jl")
include("analysis.jl")
a = "hiiiii"

end #Analyze