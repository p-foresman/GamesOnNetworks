using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")


λ = [5, 10, 20, 30, 40, 50, 60, 70, 80, 90]
errsweep = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [1000],
    [10],
    collect(0.5:-0.05:0.1),
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


errsweep2 = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [1000],
    [10],
    collect(0.19:-0.01:0.11),
    [("fractious_starting_condition", UserVariables())],
    [("partially_reinforced_equity_stopping_condition", UserVariables(:period_count=>0))],
    [
        # CompleteModelGenerator(),
        # ErdosRenyiModelGenerator(λ),
        # SmallWorldModelGenerator(λ, [0.01]),
        ScaleFreeModelGenerator(λ, [2.0]),
        # StochasticBlockModelGenerator(λ, [2], [1.0], [0.01])
    ]
)

errsweep3 = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [1000],
    [10],
    collect(0.75:-0.05:0.65),
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

errsweep4 = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [1000],
    [10],
    [0.6, 0.55],
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

errsweep5 = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [1000],
    [10],
    [0.95, 0.9, 0.85, 0.8],
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

errsweep6 = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [1000],
    [10],
    [0.09, 0.08],
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


for model in errsweep6
    simulate(model)
end