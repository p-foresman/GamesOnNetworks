using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")
include("data_functions.jl")


timeseries = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [10, 20, 30, 40],
    [10],
    [0.1],
    [("fractious_starting_condition", UserVariables())],
    [("equity_stopping_condition", UserVariables(:period_count=>0))],
    [
        CompleteModelGenerator()
    ]
)


for model in timeseries
    for _ in 1:20
        simulate(model)
    end
end


timeseries = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [10],
    [10, 13, 16, 19],
    [0.1],
    [("fractious_starting_condition", UserVariables())],
    [("equity_stopping_condition", UserVariables(:period_count=>0))],
    [
        CompleteModelGenerator()
    ]
)


for model in timeseries
    for _ in 1:20
        simulate(model)
    end
end
