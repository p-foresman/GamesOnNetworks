using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")


population_sweep_1 = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
    [10],
    [0.1],
    [("fractious_starting_condition", UserVariables())],
    [("partially_reinforced_equity_stopping_condition", UserVariables(:period_count=>0)), ("equity_stopping_condition", UserVariables())],
    [CompleteModelGenerator()]
)

population_sweep_2 = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [10, 15, 20, 25, 30, 35, 40, 45, 50],
    [10],
    [0.05],
    [("fractious_starting_condition", UserVariables())],
    [("partially_reinforced_equity_stopping_condition", UserVariables(:period_count=>0)), ("equity_stopping_condition", UserVariables())],
    [CompleteModelGenerator()]
)

population_sweep_3 = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [10, 12, 14, 16, 18, 20],
    [10],
    [0.02],
    [("fractious_starting_condition", UserVariables())],
    [("partially_reinforced_equity_stopping_condition", UserVariables(:period_count=>0)), ("equity_stopping_condition", UserVariables())],
    [CompleteModelGenerator()]
)

memory_sweep = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [10],
    collect(1:20),
    [0.1, 0.05],
    [("fractious_starting_condition", UserVariables())],
    [("partially_reinforced_equity_stopping_condition", UserVariables(:period_count=>0)), ("equity_stopping_condition", UserVariables())],
    [CompleteModelGenerator()]
)

aey_generator = ModelGeneratorSet(population_sweep_1, population_sweep_2, population_sweep_3, memory_sweep)

for model in aey_generator
    simulate(model)
end