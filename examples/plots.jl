using GamesOnNetworks, Plots, SQLite, DataFrames, ColorSchemes

#quick and dirty way to add graph type
function add_graph_type(db_filepath)
    graph_types = ["complete", "er", "sf", "sw", "sbm"]
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    DBInterface.execute(db, "ALTER TABLE graphs
                        RENAME COLUMN graph_type TO graph";)
    DBInterface.execute(db, "ALTER TABLE graphs
                        ADD graph_type TEXT NOT NULL DEFAULT ``";)
    query = DBInterface.execute(db, "SELECT COUNT(*) FROM graphs";)
    df = DataFrame(query)
    for row in 1:df[1, "COUNT(*)"]
        query = DBInterface.execute(db, "SELECT graph_params FROM graphs WHERE graph_id == $row";)
        params = DataFrame(query)[1, "graph_params"]
        for graph_type in graph_types
            if occursin(graph_type, params)
                DBInterface.execute(db, "UPDATE graphs SET graph_type = '$graph_type' WHERE graph_id = $row";)
            end
        end
    end
end

colors = [palette(:default)[11] palette(:default)[2] palette(:default)[2] palette(:default)[12] palette(:default)[9] palette(:default)[9] palette(:default)[9] palette(:default)[14]]

# main heatmap
main_heatmap_plot = GamesOnNetworks.noise_vs_structure_heatmap("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                    game_id=1,
                                    graph_params_extra=[Dict{Symbol, Any}(:title=>"Erdos-Renyi", :graph_type=>"er"),
                                                        Dict{Symbol, Any}(:title=>"Small-World (β=0.0)", :graph_type=>"sw", :β=>0.00),
                                                        Dict{Symbol, Any}(:title=>"Scale-Free (α=2)", :graph_type=>"sf", :α=>2),
                                                        Dict{Symbol, Any}(:title=>"Stochastic Block Model (p_in=1.0, p_out=0.01)", :graph_type=>"sbm", :p_in=>1.0, :p_out=>0.01)],
                                    errors=[0.02, 0.05, 0.1, 0.2],
                                    mean_degrees=[3.0, 5.0, 10.0],
                                    number_agents=100,
                                    memory_length=10,
                                    starting_condition_id=1,
                                    stopping_condition_id=1,
                                    sample_size=20
)

transition_time_stopping_condition_comparison_population_plot = GamesOnNetworks.transition_times_vs_population_stopping_conditions("./sqlite/slurm_simulation_saves_incomplete.sqlite",
                                                                    game_id=1,
                                                                    number_agents_list=[10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
                                                                    memory_length=10,
                                                                    errors=[0.1],
                                                                    graph_ids=[61],
                                                                    starting_condition_ids=[1],
                                                                    stopping_condition_ids=[1, 2],
                                                                    sample_size=20,
                                                                    conf_intervals=true,
                                                                    legend_labels=["Equity Behavioral", "Equity Psychological"],
                                                                    colors=colors[4:5]
)


transition_time_stopping_condition_comparison_memory_length_plot = GamesOnNetworks.transition_times_vs_memory_length_stopping_conditions("./sqlite/slurm_simulation_saves_incomplete.sqlite",
                                                                    game_id=1,
                                                                    memory_length_list=[10, 13, 16, 19],
                                                                    number_agents=10,
                                                                    errors=[0.1],
                                                                    graph_ids=[61],
                                                                    starting_condition_ids=[1],
                                                                    stopping_condition_ids=[1, 2],
                                                                    sample_size=20,
                                                                    conf_intervals=true,
                                                                    legend_labels=["Equity Behavioral", "Equity Psychological"],
                                                                    colors=colors[4:5]
)




##### following 3 are for AEY population sweep replication
population_sweep_plot = GamesOnNetworks.transition_times_vs_population_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite",
                                                                    game_id=1,
                                                                    number_agents_list=[10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
                                                                    memory_length=10,
                                                                    errors=[0.1],
                                                                    graph_ids=[61],
                                                                    starting_condition_id=1,
                                                                    stopping_condition_id=2,
                                                                    sample_size=20,
                                                                    conf_intervals=true,
                                                                    legend_labels=["ϵ = 10%"],
                                                                    colors=[colors[4]]
)

GamesOnNetworks.transition_times_vs_population_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite",
                                                                    game_id=1,
                                                                    number_agents_list=[10, 15, 20, 25, 30, 35, 40, 45, 50],
                                                                    memory_length=10,
                                                                    errors=[0.05],
                                                                    graph_ids=[61],
                                                                    starting_condition_id=1,
                                                                    stopping_condition_id=2,
                                                                    sample_size=20,
                                                                    conf_intervals=true,
                                                                    legend_labels=["ϵ = 5%"],
                                                                    colors=[colors[1]],
                                                                    sim_plot=population_sweep_plot
)

GamesOnNetworks.transition_times_vs_population_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite",
                                                                    game_id=1,
                                                                    number_agents_list=[10, 12, 14, 16, 18, 20],
                                                                    memory_length=10,
                                                                    errors=[0.02],
                                                                    graph_ids=[61],
                                                                    starting_condition_id=1,
                                                                    stopping_condition_id=2,
                                                                    sample_size=20,
                                                                    conf_intervals=true,
                                                                    legend_labels=["ϵ = 2%"],
                                                                    colors=[colors[5]],
                                                                    sim_plot=population_sweep_plot
)


######## following 2 plots are memory sweep AEY replication
memory_sweep_plot = GamesOnNetworks.transition_times_vs_memory_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite",
                                                                    game_id=1,
                                                                    memory_length_list=[10, 13, 16, 19],
                                                                    number_agents=10,
                                                                    errors=[0.05],
                                                                    graph_ids=[61],
                                                                    starting_condition_id=1,
                                                                    stopping_condition_id=2,
                                                                    sample_size=20,
                                                                    conf_intervals=true,
                                                                    legend_labels=["ϵ = 5%"],
                                                                    colors=[colors[1]]
)

GamesOnNetworks.transition_times_vs_memory_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite",
                                                game_id=1,
                                                memory_length_list=[10, 13, 16, 19],
                                                number_agents=10,
                                                errors=[0.1],
                                                graph_ids=[61],
                                                starting_condition_id=1,
                                                stopping_condition_id=2,
                                                sample_size=20,
                                                conf_intervals=true,
                                                legend_labels=["ϵ = 10%"],
                                                colors=[colors[4]],
                                                sim_plot=memory_sweep_plot
)




# random graph-specific heatmaps
er_heatmap_plot = GamesOnNetworks.noise_vs_structure_heatmap("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                    game_id=1,
                                    graph_params_extra=[Dict{Symbol, Any}(:title=>"Erdos-Renyi", :graph_type=>"er"),
                                                        Dict{Symbol, Any}(:title=>"Erdos-Renyi", :graph_type=>"er")],
                                    errors=[0.02, 0.05, 0.1, 0.2],
                                    mean_degrees=[3.0, 5.0, 10.0],
                                    number_agents=100,
                                    memory_length=10,
                                    starting_condition_id=1,
                                    stopping_condition_id=1,
                                    sample_size=20
)

sw_heatmap_plot = GamesOnNetworks.noise_vs_structure_heatmap("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                    game_id=1,
                                    graph_params_extra=[Dict{Symbol, Any}(:title=>"Small-World (β=0.0)", :graph_type=>"sw", :β=>0.0),
                                                        Dict{Symbol, Any}(:title=>"Small-World (β=0.01)", :graph_type=>"sw", :β=>0.01),
                                                        Dict{Symbol, Any}(:title=>"Small-World (β=0.05)", :graph_type=>"sw", :β=>0.05),
                                                        Dict{Symbol, Any}(:title=>"Small-World (β=1.0)", :graph_type=>"sw", :β=>1.0),
                                                        Dict{Symbol, Any}(:title=>"Erdos-Renyi", :graph_type=>"er")],
                                    errors=[0.02, 0.05, 0.1, 0.2],
                                    mean_degrees=[3.0, 5.0, 10.0],
                                    number_agents=100,
                                    memory_length=10,
                                    starting_condition_id=1,
                                    stopping_condition_id=1,
                                    sample_size=20
)

sf_heatmap_plot = GamesOnNetworks.noise_vs_structure_heatmap("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                    game_id=1,
                                    graph_params_extra=[Dict{Symbol, Any}(:title=>"Scale-Free (α=2)", :graph_type=>"sf", :α=>2),
                                                        Dict{Symbol, Any}(:title=>"Scale-Free (α=3)", :graph_type=>"sf", :α=>3),
                                                        Dict{Symbol, Any}(:title=>"Scale-Free (α=4)", :graph_type=>"sf", :α=>4),
                                                        Dict{Symbol, Any}(:title=>"Scale-Free (α=100)", :graph_type=>"sf", :α=>100),
                                                        Dict{Symbol, Any}(:title=>"Erdos-Renyi", :graph_type=>"er")],
                                    errors=[0.02, 0.05, 0.1, 0.2],
                                    mean_degrees=[3.0, 5.0, 10.0],
                                    number_agents=100,
                                    memory_length=10,
                                    starting_condition_id=1,
                                    stopping_condition_id=1,
                                    sample_size=20
)



sbm_heatmap_plot = GamesOnNetworks.noise_vs_structure_heatmap("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                    game_id=1,
                                    graph_params_extra=[Dict{Symbol, Any}(:title=>"SBM (p_in=1.0, p_out=0.01)", :graph_type=>"sbm", :p_in=>1.0, :p_out=>0.01),
                                                        Dict{Symbol, Any}(:title=>"SBM (p_in=0.75, p_out=0.01)", :graph_type=>"sbm", :p_in=>0.75, :p_out=>0.01),
                                                        Dict{Symbol, Any}(:title=>"SBM (p_in=0.5, p_out=0.01)", :graph_type=>"sbm", :p_in=>0.5, :p_out=>0.01),
                                                        Dict{Symbol, Any}(:title=>"SBM (p_in=0.25, p_out=0.01)", :graph_type=>"sbm", :p_in=>0.25, :p_out=>0.01),
                                                        Dict{Symbol, Any}(:title=>"SBM (p_in=0.01, p_out=0.01)", :graph_type=>"sbm", :p_in=>0.01, :p_out=>0.01),
                                                        Dict{Symbol, Any}(:title=>"Erdos-Renyi", :graph_type=>"er")],
                                    errors=[0.02, 0.05, 0.1, 0.2],
                                    mean_degrees=[3.0, 5.0, 10.0],
                                    number_agents=100,
                                    memory_length=10,
                                    starting_condition_id=1,
                                    stopping_condition_id=1,
                                    sample_size=20
)

#random graph extra parameter sweeps (with λ and error fixed?) (can definitely do this with ER)
er_lambda_sweep = GamesOnNetworks.transition_times_vs_graph_params_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                                                            game_id=1,
                                                                            memory_length=10,
                                                                            number_agents=100,
                                                                            errors=[0.02, 0.05, 0.1, 0.2],
                                                                            graph_params_extra=[Dict{Symbol, Any}(:graph_type=>"er", :λ=>3.0),
                                                                                                Dict{Symbol, Any}(:graph_type=>"er", :λ=>5.0),
                                                                                                Dict{Symbol, Any}(:graph_type=>"er", :λ=>10.0)],
                                                                            sweep_param=:λ,
                                                                            starting_condition_id=1,
                                                                            stopping_condition_id=1,
                                                                            sample_size=20,
                                                                            conf_intervals=true,
                                                                            legend_labels=["", "", "", ""],
                                                                            colors=[colors[8], colors[4], colors[5], colors[1]],
                                                                            plot_title="")



sw_beta_sweep = GamesOnNetworks.transition_times_vs_graph_params_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                                                            game_id=1,
                                                                            memory_length=10,
                                                                            number_agents=100,
                                                                            errors=[0.02, 0.05, 0.1, 0.2],
                                                                            graph_params_extra=[Dict{Symbol, Any}(:graph_type=>"sw", :λ=>5.0, :β=>0.0),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sw", :λ=>5.0, :β=>0.01),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sw", :λ=>5.0, :β=>0.05),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sw", :λ=>5.0, :β=>1.0)],
                                                                            sweep_param=:β,
                                                                            starting_condition_id=1,
                                                                            stopping_condition_id=1,
                                                                            sample_size=20,
                                                                            conf_intervals=true,
                                                                            legend_labels=["", "", "", ""],
                                                                            colors=[colors[8], colors[4], colors[5], colors[1]],
                                                                            plot_title="")


sf_alpha_sweep = GamesOnNetworks.transition_times_vs_graph_params_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                                                            game_id=1,
                                                                            memory_length=10,
                                                                            number_agents=100,
                                                                            errors=[0.02, 0.05, 0.1, 0.2],
                                                                            graph_params_extra=[Dict{Symbol, Any}(:graph_type=>"sf", :λ=>5.0, :α=>2.0),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sf", :λ=>5.0, :α=>3.0),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sf", :λ=>5.0, :α=>4.0),],
                                                                                                # Dict{Symbol, Any}(:graph_type=>"sf", :λ=>5.0, :α=>100.0)],
                                                                            sweep_param=:α,
                                                                            starting_condition_id=1,
                                                                            stopping_condition_id=1,
                                                                            sample_size=20,
                                                                            conf_intervals=true,
                                                                            legend_labels=["", "", "", ""],
                                                                            colors=[colors[8], colors[4], colors[5], colors[1]],
                                                                            plot_title="")


sbm_pin_sweep = GamesOnNetworks.transition_times_vs_graph_params_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                                                            game_id=1,
                                                                            memory_length=10,
                                                                            number_agents=100,
                                                                            errors=[0.02, 0.05, 0.1, 0.2],
                                                                            graph_params_extra=[Dict{Symbol, Any}(:graph_type=>"sbm", :λ=>5.0, :p_in=>0.01),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sbm", :λ=>5.0, :p_in=>0.25),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sbm", :λ=>5.0, :p_in=>0.5),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sbm", :λ=>5.0, :p_in=>0.75),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sbm", :λ=>5.0, :p_in=>1.0)],
                                                                            sweep_param=:p_in,
                                                                            starting_condition_id=1,
                                                                            stopping_condition_id=1,
                                                                            sample_size=20,
                                                                            conf_intervals=true,
                                                                            legend_labels=["", "", "", ""],
                                                                            colors=[colors[8], colors[4], colors[5], colors[1]],
                                                                            plot_title="")

#boxplots with ER as "null" showing other random graph types approximating as extra params approach certain values? (can do this with boxplot)


sw_lambda_sweep = GamesOnNetworks.transition_times_vs_graph_params_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                                                            game_id=1,
                                                                            memory_length=10,
                                                                            number_agents=100,
                                                                            errors=[0.02, 0.05, 0.1, 0.2],
                                                                            graph_params_extra=[Dict{Symbol, Any}(:graph_type=>"sw", :λ=>3.0, :β=>0.01),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sw", :λ=>5.0, :β=>0.01),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sw", :λ=>10.0, :β=>0.01),],
                                                                                                # Dict{Symbol, Any}(:graph_type=>"sw", :λ=>5.0, :β=>0.0)],
                                                                            sweep_param=:λ,
                                                                            starting_condition_id=1,
                                                                            stopping_condition_id=1,
                                                                            sample_size=20,
                                                                            conf_intervals=true,
                                                                            legend_labels=["", "", "", ""],
                                                                            colors=[colors[8], colors[4], colors[5], colors[1]],
                                                                            plot_title="")



sf_lambda_sweep = GamesOnNetworks.transition_times_vs_graph_params_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                                                            game_id=1,
                                                                            memory_length=10,
                                                                            number_agents=100,
                                                                            errors=[0.02, 0.05, 0.1, 0.2],
                                                                            graph_params_extra=[Dict{Symbol, Any}(:graph_type=>"sf", :λ=>3.0, :α=>2.0),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sf", :λ=>5.0, :α=>2.0),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sf", :λ=>10.0, :α=>2.0),],
                                                                                                # Dict{Symbol, Any}(:graph_type=>"sf", :λ=>5.0, :α=>100.0)],
                                                                            sweep_param=:λ,
                                                                            starting_condition_id=1,
                                                                            stopping_condition_id=1,
                                                                            sample_size=20,
                                                                            conf_intervals=true,
                                                                            legend_labels=["", "", "", ""],
                                                                            colors=[colors[8], colors[4], colors[5], colors[1]],
                                                                            plot_title="")

#
sbm_lambda_sweep = GamesOnNetworks.transition_times_vs_graph_params_sweep("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                                                            game_id=1,
                                                                            memory_length=10,
                                                                            number_agents=100,
                                                                            errors=[0.02, 0.05, 0.1, 0.2],
                                                                            graph_params_extra=[Dict{Symbol, Any}(:graph_type=>"sbm", :λ=>3.0, :p_in=>0.75),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sbm", :λ=>5.0, :p_in=>0.75),
                                                                                                Dict{Symbol, Any}(:graph_type=>"sbm", :λ=>10.0, :p_in=>0.75),],
                                                                                                # Dict{Symbol, Any}(:graph_type=>"sbm", :λ=>5.0, :p_in=>0.75),
                                                                                                # Dict{Symbol, Any}(:graph_type=>"sbm", :λ=>5.0, :p_in=>1.0)],
                                                                            sweep_param=:λ,
                                                                            starting_condition_id=1,
                                                                            stopping_condition_id=1,
                                                                            sample_size=20,
                                                                            conf_intervals=true,
                                                                            legend_labels=["", "", "", ""],
                                                                            colors=[colors[8], colors[4], colors[5], colors[1]],
                                                                            plot_title="")