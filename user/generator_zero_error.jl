using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")


model_generator = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [100],
    [10],
    [0.0],
    [("fractious_starting_condition", UserVariables())],
    [("period_cutoff_stopping_condition", UserVariables(:period_cutoff=>1000000))],
    [
        CompleteModelGenerator(),
        # ErdosRenyiModelGenerator([20]),
        # SmallWorldModelGenerator([10], [0.01]),
        # ScaleFreeModelGenerator([10], [2.0]),
        # StochasticBlockModelGenerator([10], [2], [1.0], [0.01])
    ]
)


for model in model_generator
    simulate(model)
end