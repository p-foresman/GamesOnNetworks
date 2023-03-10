using GamesOnNetworks, ColorSchemes, Plots

graph_ids = [1, 2, 3, 4, 5, 6, 7, 8]

x_labels = ["1" "2" "3" "4" "5" "6" "7" "8"]
colors = [palette(:default)[11] palette(:default)[2] palette(:default)[2] palette(:default)[12] palette(:default)[9] palette(:default)[9] palette(:default)[9] palette(:default)[14]]

test_plot = transitionTimesBoxPlot("./sqlite/SimulationSaves.sqlite", game_id=1, number_agents=10, memory_length=16, error=0.05, graph_ids=graph_ids, x_labels=x_labels, colors=colors, sample_size=20)


test_plot_2 = numberAgentsTransitionTimeLinePlot("./sqlite/SimulationSaves.sqlite"; game_id=1, number_agents_list=[10, 20, 30, 40], memory_length=10, errors=[0.1], graph_ids=[1, 2], sample_size=20, conf_intervals=true)

test_plot_3 = memoryLengthTransitionTimeLinePlot("./sqlite/SimulationSaves.sqlite"; game_id=1, number_agents=10, memory_length_list=[10, 13, 16, 19], errors=[0.1], graph_ids=[1, 2, 3, 4], sample_size=20, conf_intervals=true)

