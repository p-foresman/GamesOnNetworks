using GamesOnNetworks, ColorSchemes, Plots

graph_ids = [1, 2, 3, 4, 5, 6, 7, 8]

x_labels = ["1" "2" "3" "4" "5" "6" "7" "8"]
colors = [palette(:default)[11] palette(:default)[2] palette(:default)[2] palette(:default)[12] palette(:default)[9] palette(:default)[9] palette(:default)[9] palette(:default)[14]]

test_plot = transitionTimesBoxPlot("./sqlite/SimulationSaves.sqlite", game_id=1, number_agents=10, memory_length=16, error=0.05, graph_ids=graph_ids, x_labels=x_labels, colors=colors, sample_size=20)

legend_labels = ["Complete", "Erdos-Renyi λ=1", "Erdos-Renyi λ=5", "Small World"]
colors = [palette(:default)[11], palette(:default)[2], palette(:default)[12], palette(:default)[9]]
error_styles = [(:dash, nothing), (:solid, nothing)]
test_plot_2 = numberAgentsTransitionTimeLinePlot("./sqlite/SlurmSimulationSaves.sqlite"; game_id=1, number_agents_list=[10, 20, 30, 40, 50, 60, 70, 80, 90, 100], memory_length=10, errors=[0.05, 0.1], graph_ids=[1, 2, 3, 4, 5, 6, 7, 8], sample_size=19, conf_intervals=true, legend_labels=legend_labels, colors=colors, error_styles=error_styles)


legend_labels = ["Complete", "Erdos-Renyi λ=1", "Erdos-Renyi λ=5", "Small World", "a", "b", "c", "d"]
colors = [palette(:default)[11], palette(:default)[2], palette(:default)[12], palette(:default)[9], palette(:default)[11], palette(:default)[2], palette(:default)[12], palette(:default)[9]]
error_styles = [(:dash, nothing), (:solid, nothing)]
test_plot_3 = memoryLengthTransitionTimeLinePlot("./sqlite/SlurmSimulationSaves.sqlite"; game_id=1, number_agents=10, memory_length_list=[10, 13, 16, 19, 22, 25], errors=[0.05, 0.1], graph_ids=[1, 2, 3, 4, 5, 6, 7, 8], sample_size=20, conf_intervals=true, legend_labels=legend_labels, colors=colors, error_styles=error_styles)

