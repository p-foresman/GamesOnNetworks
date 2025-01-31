using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")


# const model = Model(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
#                         Parameters(100, 10, 0.1, "fractious_starting_condition", "equity_behavioral", user_variables=UserVariables(:period_count=>0)),
#                         ErdosRenyiModel(7))

const model = Model(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                        Parameters(10, 10, 0.1, "fractious_starting_condition", "period_cutoff_stopping_condition", user_variables=UserVariables(:period_cutoff=>10000)),
                        CompleteModel())

const model2 = Model(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                    Parameters(10, 10, 0.1, "fractious_starting_condition", "equity_stopping_condition"),
                    CompleteModel())

const model3 = Model(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                    Parameters(10, 10, 0.1, "fractious_starting_condition", "period_cutoff_stopping_condition", user_variables=UserVariables(:period_cutoff=>100000000)),
                    CompleteModel())

const model4 = Model(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                    Parameters(30, 19, 0.09, "fractious_starting_condition", "equity_stopping_condition"),
                    CompleteModel())

const m = Model(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                    Parameters(10, 10, 0.1, "fractious_starting_condition", "period_cutoff_stopping_condition", user_variables=UserVariables(:period_cutoff=>10000000)),
                    ErdosRenyiModel(5.0))
# const g = generate_graph(m)
# GamesOnNetworks.graph!(m, g)
                    

println(model)

# simulate(model)


# if GamesOnNetworks.db_has_incomplete_simulations()
#     println("simulating incomplete")
#     simulate()
# else
#     println("simulating model")
#     simulate(model)
# end
