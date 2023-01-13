#Plotting for box plot (all network classes)
function transitionTimesBoxPlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length, error::Float64, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, x_labels, colors, sample_size::Integer)
    df = querySimulationsForBoxPlot(db_filepath, game_id=game_id, number_agents=number_agents, memory_length=memory_length, error=error, graph_ids=graph_ids, sample_size=sample_size)
    transition_times_matrix = zeros(sample_size, length(graph_ids))
    println(df)
    for (graph_number, graph_id) in enumerate(graph_ids)
        filtered_df = filter(:graph_id => id -> id == graph_id, df)
        transition_times_matrix[:, graph_number] = filtered_df[:, :periods_elapsed]
    end
    # colors = [palette(:default)[11] palette(:default)[2] palette(:default)[2]] #palette(:default)[12] palette(:default)[9] palette(:default)[9] palette(:default)[9] palette(:default)[14]
    # x_vals = ["Complete" "ER λ=1" "ER λ=5"] #"SW" "SF α=2" "SF α=4" "SF α=8" "SBM"
    sim_plot = boxplot(x_labels,
                    transition_times_matrix,
                    leg = false,
                    yscale = :log10,
                    xlabel = "Graph",
                    ylabel = "Transtition Time (periods)",
                    fillcolor = colors)

    return sim_plot
end


function initLinePlot(params::SimParams)
    if params.iteration_param == :memorylength
        x_label = "Memory Length"
        x_lims = (8,20)
        x_ticks = 8:1:20
    elseif params.iteration_param == :numberagents
        x_label = "Number of Agents"
        x_lims = (0,110)
        x_ticks = 0:10:100
    end
    sim_plot = plot(xlabel = x_label,
                    xlims = x_lims,
                    xticks = x_ticks,
                    ylabel = "Transition Time",
                    yscale = :log10,
                    legend_position = :topleft)
    return sim_plot
end