using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")


λs = collect(30:-1:5)
N1000_m10_generator = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [1000],
    [10],
    collect(0.15:-0.01:0.05),
    [("fractious_starting_condition", UserVariables())],
    [("partially_reinforced_equity_stopping_condition", UserVariables(:period_count=>0))],
    [
        ErdosRenyiModelGenerator(λs),
        SmallWorldModelGenerator(λs, [0.0, 0.0001, 0.001, 0.01, 0.1, 0.5, 1.0]),
        ScaleFreeModelGenerator(λs, collect(2.0:0.05:5.0)),
        StochasticBlockModelGenerator(λs, [2], [0.01, 0.2, 0.4, 0.6, 0.8, 1.0], [0.01])
    ]
)