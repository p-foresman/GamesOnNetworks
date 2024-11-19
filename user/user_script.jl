using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")


# const model = SimModel(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
#                         SimParams(100, 10, 0.1, "fractious_starting_condition", "equity_behavioral", user_variables=UserVariables(:period_count=>0)),
#                         ErdosRenyiModel(7))

const model = SimModel(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                        SimParams(10, 10, 0.1, "fractious_starting_condition", "period_cutoff", user_variables=UserVariables(:period_cutoff=>10000000)),
                        CompleteModel())

println(model)

# simulate(model)


# if GamesOnNetworks.db_has_incomplete_simulations()
#     println("simulating incomplete")
#     simulate()
# else
#     println("simulating model")
#     simulate(model)
# end