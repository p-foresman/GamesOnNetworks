using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")


λ = [5, 10, 20, 30, 40, 50, 60, 70, 80, 90]#[5, 10, 20]
gen = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [100],
    collect(3:20),
    [0.1],
    [("fractious_starting_condition", UserVariables())],
    [("partially_reinforced_equity_stopping_condition", UserVariables(:period_count=>0))],
    [
        CompleteModelGenerator(),
        ErdosRenyiModelGenerator(λ),
        SmallWorldModelGenerator(λ, [0.01]),
        ScaleFreeModelGenerator(λ, [2.0]),
        StochasticBlockModelGenerator(λ, [2], [1.0], [0.01])
    ]
)


for model in gen
    simulate(model)
end