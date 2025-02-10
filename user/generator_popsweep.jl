using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")


gen1 = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    collect(10:10:90),
    [10],
    [0.1],
    [("fractious_starting_condition", UserVariables())],
    [("partially_reinforced_equity_stopping_condition", UserVariables(:period_count=>0))],
    [
        CompleteModelGenerator(),
        ErdosRenyiModelGenerator([5]),
        SmallWorldModelGenerator([5], [0.01]),
        ScaleFreeModelGenerator([5], [2.0]),
        StochasticBlockModelGenerator([5], [2], [1.0], [0.01])
    ]
)

λ = [30, 40, 50, 60, 70, 80, 90]#[5, 10, 20]
gen2 = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000],
    [10],
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


model_generator = ModelGeneratorSet(gen1, gen2)


for model in gen2
    simulate(model)
end