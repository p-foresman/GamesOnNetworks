using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")


λ = collect(5:40)
sf_sweep = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [1000],
    [10],
    collect(0.05:0.01:0.15),
    [("fractious_starting_condition", UserVariables())],
    [("partially_reinforced_equity_stopping_condition", UserVariables(:period_count=>0))],
    [
        ScaleFreeModelGenerator(λ, collect(2.0:0.1:3.0)),
    ]
)


for model in sf_sweep
    simulate(model)
end