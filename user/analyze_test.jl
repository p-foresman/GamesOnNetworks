using GamesOnNetworks
# GamesOnNetworks.configure("./config/aey.toml")

qp_games = Database.Query_games(["Bargaining Game"])
sql_games = Database.sql(qp_games)
q_games = Database.db_query(sql_games)

qp_parameters = Database.Query_parameters([20, 30], [10], [0.1, 0.05], ["fractious_starting_condition"], ["equity_stopping_condition"])
sql_parameters = Database.sql(qp_parameters)
q_parameters = Database.db_query(sql_parameters)

qp_graphmodels = Database.Query_graphmodels([Database.Query_graphmodels_CompleteModel(), Database.Query_graphmodels_ErdosRenyiModel([5.0, 10.0]), Database.Query_graphmodels_StochasticBlockModel([5, 10], [2], [.5, .75], [0.01])])
sql_graphmodels = Database.sql(qp_graphmodels)
filter_graphmodels = Database.sql_filter(GamesOnNetworks.SETTINGS.database, qp_graphmodels)
q_graphmodels = Database.db_query(qp_graphmodels)

qp_models = Database.Query_models(qp_games, qp_parameters, qp_graphmodels)
sql_models = Database.sql(qp_models)
q_models = Database.db_query(sql_models)

qp_simulations = Database.Query_simulations(qp_games, qp_parameters, qp_graphmodels, complete=true, sample_size=20)
sql_simulations = Database.sql(qp_simulations)
q_simulations = Database.db_query(qp_simulations)


Database.sql(GamesOnNetworks.SETTINGS.database, Database.Query_graphmodels_ErdosRenyiModel([5.0, 10.0]))
Database.db_query(Database.sql(GamesOnNetworks.SETTINGS.database, Database.Query_graphmodels_CompleteModel()))



#test plot
colors = [Analyze.palette(:default)[11] Analyze.palette(:default)[2] Analyze.palette(:default)[2] Analyze.palette(:default)[12] Analyze.palette(:default)[9] Analyze.palette(:default)[9] Analyze.palette(:default)[9] Analyze.palette(:default)[14]]
qp_games = Database.Query_games(["Bargaining Game"])
qp_parameters_1 = Database.Query_parameters([10, 20, 30, 40, 50, 60, 70, 80, 90, 100], [10], [0.1], ["fractious_starting_condition"], ["equity_stopping_condition"])
qp_parameters_2 = Database.Query_parameters([10, 15, 20, 25, 30, 35, 40, 45, 50], [10], [0.05], ["fractious_starting_condition"], ["equity_stopping_condition"])
qp_parameters_3 = Database.Query_parameters([10, 12, 14, 16, 18, 20], [10], [0.02], ["fractious_starting_condition"], ["equity_stopping_condition"])
qp_graphmodels = Database.Query_graphmodels([Database.Query_graphmodels_CompleteModel()])
qp_simulations_1 = Database.Query_simulations(qp_games, qp_parameters_1, qp_graphmodels, complete=true, sample_size=20)
qp_simulations_2 = Database.Query_simulations(qp_games, qp_parameters_2, qp_graphmodels, complete=true, sample_size=20)
qp_simulations_3 = Database.Query_simulations(qp_games, qp_parameters_3, qp_graphmodels, complete=true, sample_size=20)

a = Analyze.transition_times_vs_population_sweep_new(qp_simulations, 
                                                conf_intervals=true,
                                                legend_labels=["ϵ = 2%"],
                                                colors=[colors[5]]
)

b = Analyze.single_parameter_sweep(:number_agents, qp_simulations_1, qp_simulations_2, qp_simulations_3, 
                                conf_intervals=true,
                                legend_labels=["ϵ = 10%", "ϵ = 5%", "ϵ = 2%"],
                                # colors=[colors[1], colors[2], colors[7]],

                                xlabel="Population",
                                xlims = (0,110),
                                xticks = 0:10:110,
                                ylabel="Transition Time",
                                yscale = :log10,
                                legend_position = :topleft,
                                size=(1300, 700),
                                margin=10Analyze.Plots.mm,
                                title="Transition Time vs Population",
                                thickness_scaling=1.2,
)