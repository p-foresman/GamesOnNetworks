using GamesOnNetworks
GamesOnNetworks.configure("./aey.toml")

qp_games = Database.Query_games(["Bargaining Game"])
sql_games = Database.sql(qp_games)
q_games = Database.db_query(sql_games)

qp_parameters = Database.Query_parameters([20, 30], [10], [0.1, 0.05], ["fractious_starting_condition"], ["equity_stopping_condition"])
sql_parameters = Database.sql(qp_parameters)
q_parameters = Database.db_query(sql_parameters)

qp_graphmodels = Database.Query_graphmodels([Database.Query_CompleteModel(), Database.Query_ErdosRenyiModel([5.0, 10.0]), Database.Query_StochasticBlockModel([5, 10], [2], [.5, .75], [0.01])])
sql_graphmodels = Database.sql(qp_graphmodels)
filter_graphmodels = Database.sql_filter(GamesOnNetworks.SETTINGS.database, qp_graphmodels)
q_graphmodels = Database.db_query(qp_graphmodels)

qp_models = Database.Query_models(qp_games, qp_parameters, qp_graphmodels)
sql_models = Database.sql(qp_models)
q_models = Database.db_query(sql_models)

qp_simulations = Database.Query_simulations(qp_games, qp_parameters, qp_graphmodels, complete=true, sample_size=20)
sql_simulations = Database.sql(qp_simulations)
q_simulations = Database.db_query(qp_simulations)



#test plot
colors = [Analyze.palette(:default)[11] Analyze.palette(:default)[2] Analyze.palette(:default)[2] Analyze.palette(:default)[12] Analyze.palette(:default)[9] Analyze.palette(:default)[9] Analyze.palette(:default)[9] Analyze.palette(:default)[14]]
qp_games = Database.Query_games(["Bargaining Game"])
qp_parameters = Database.Query_parameters([10, 20, 30, 40, 50, 60, 70, 80, 90, 100], [10], [0.1], ["fractious_starting_condition"], ["equity_stopping_condition"])
qp_graphmodels = Database.Query_graphmodels([Database.Query_CompleteModel()])
qp_simulations = Database.Query_simulations(qp_games, qp_parameters, qp_graphmodels, complete=true, sample_size=20)
Analyze.transition_times_vs_population_sweep_new(qp_simulations, 
                                                conf_intervals=true,
                                                legend_labels=["ϵ = 2%"],
                                                colors=[colors[5]]
)