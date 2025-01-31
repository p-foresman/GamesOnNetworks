using GamesOnNetworks
# GamesOnNetworks.configure("./config/aey.toml")

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

a = Analyze.single_parameter_sweep(:number_agents, qp_simulations_1, qp_simulations_2, qp_simulations_3, 
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

λs = collect(2.0:0.5:10.0)
# main heatmap
q = Analyze.multiple_two_parameter_sweep_heatmap(:graphmodel_type, :λ, :error,
                                        Database.Query_simulations(Database.Query_games(["Bargaining Game"]),
                                            Database.Query_parameters([100], [10], [0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1], ["fractious_starting_condition"], ["partially_reinforced_equity_stopping_condition"]),
                                            Database.Query_graphmodels(
                                                [Database.Query_graphmodels_ErdosRenyiModel(λs),
                                                Database.Query_graphmodels_SmallWorldModel(λs, [0.01]),
                                                Database.Query_graphmodels_ScaleFreeModel(λs, [2]),
                                                Database.Query_graphmodels_StochasticBlockModel(λs, [2], [1.0], [0.01])]
                                            ),
                                            complete=true,
                                            sample_size=20
                                        );
                                        filename="main_heatmap_plot",
                                        statistic=:median,
                                        x_sweep_parameter_label="Mean Degree",
                                        y_sweep_parameter_label="Error",
                                        subplot_titles=["Erdos-Renyi", "Small World (β=0.01)", "Scale Free (α=2)", "Stochastic Block Model (p_in=1.0, p_out=0.01)"],
                                        size=(1000, 1000),
                                        left_margin=10Analyze.Plots.mm,
                                        right_margin=10Analyze.Plots.mm
)


q2 = Analyze.multiple_two_parameter_sweep_heatmap([:graphmodel_type, :β], :λ, :error,
                                        Database.Query_simulations(Database.Query_games(["Bargaining Game"]),
                                            Database.Query_parameters([100], [10], [0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1], ["fractious_starting_condition"], ["partially_reinforced_equity_stopping_condition"]),
                                            Database.Query_graphmodels(
                                                [Database.Query_graphmodels_SmallWorldModel(λs, [0.01, 0.1, 0.3, 0.6, 0.9])],
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [0.001]),
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [0.01]),
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [0.1]),
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [1.0])]
                                            ),
                                            complete=true,
                                            sample_size=20
                                        );
                                        filename="main_heatmap_plot",
                                        statistic=:mean,
                                        x_sweep_parameter_label="Mean Degree",
                                        y_sweep_parameter_label="Error",
                                        subplot_titles=["Small World (β=0.01)", "Small World (β=0.1)", "Small World (β=0.3)", "Small World (β=0.6)", "Small World (β=1.0)"],
                                        size=(1000, 1000),
                                        left_margin=10Analyze.Plots.mm,
                                        right_margin=10Analyze.Plots.mm
)


q2 = Analyze.multiple_two_parameter_sweep_heatmap([:graphmodel_type, :α], :λ, :error,
                                        Database.Query_simulations(Database.Query_games(["Bargaining Game"]),
                                            Database.Query_parameters([100], [10], [0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1], ["fractious_starting_condition"], ["partially_reinforced_equity_stopping_condition"]),
                                            Database.Query_graphmodels(
                                                [Database.Query_graphmodels_ScaleFreeModel(λs, collect(2.0:.2:3.0))],
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [0.001]),
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [0.01]),
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [0.1]),
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [1.0])]
                                            ),
                                            complete=true,
                                            sample_size=20
                                        );
                                        filename="main_heatmap_plot",
                                        statistic=:mean,
                                        x_sweep_parameter_label="Mean Degree",
                                        y_sweep_parameter_label="Error",
                                        # subplot_titles=["Small World (β=0.01)", "Small World (β=0.1)", "Small World (β=0.3)", "Small World (β=0.6)", "Small World (β=1.0)"],
                                        size=(1000, 1000),
                                        left_margin=10Analyze.Plots.mm,
                                        right_margin=10Analyze.Plots.mm
)



q2 = Analyze.multiple_two_parameter_sweep_heatmap([:graphmodel_type, :p_in], :λ, :error,
                                        Database.Query_simulations(Database.Query_games(["Bargaining Game"]),
                                            Database.Query_parameters([100], [10], [0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1], ["fractious_starting_condition"], ["partially_reinforced_equity_stopping_condition"]),
                                            Database.Query_graphmodels(
                                                [Database.Query_graphmodels_StochasticBlockModel(λs, [2], [1.0, 0.8, 0.5, 0.2, 0.01], [0.01])],
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [0.001]),
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [0.01]),
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [0.1]),
                                                # Database.Query_graphmodels_SmallWorldModel(λs, [1.0])]
                                            ),
                                            complete=true,
                                            sample_size=20
                                        );
                                        filename="main_heatmap_plot",
                                        statistic=:mean,
                                        x_sweep_parameter_label="Mean Degree",
                                        y_sweep_parameter_label="Error",
                                        # subplot_titles=["Small World (β=0.01)", "Small World (β=0.1)", "Small World (β=0.3)", "Small World (β=0.6)", "Small World (β=1.0)"],
                                        size=(1000, 1000),
                                        left_margin=10Analyze.Plots.mm,
                                        right_margin=10Analyze.Plots.mm
)