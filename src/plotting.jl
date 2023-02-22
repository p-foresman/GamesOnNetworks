#Plotting for box plot (all network classes)
function transitionTimesBoxPlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length::Integer, error::Float64, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, x_labels, colors, sample_size::Integer)
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




function memoryLengthTransitionTimeLinePlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_lengths::Union{Vector{<:Integer}, Nothing} = nothing, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
    memory_lengths = sort(memory_lengths)
    errors = sort(errors)
    graph_ids = sort(graph_ids)
    
    df = querySimulationsForMemoryLengthLinePlot(db_filepath, game_id=game_id, number_agents=number_agents, memory_lengths=memory_lengths, errors=errors, graph_ids=graph_ids, sample_size=sample_size)
    println(df)
    line_count = length(errors) * length(graph_ids)
    println("line count: " * "$line_count")
    series_matrix = zeros(length(memory_lengths), line_count) #this is an issue if memory_lengths/errors/graph_ids=nothing***
    plot_line_number = 1 #this will make the lines unordered***
    
    println(series_matrix)
    legend_labels = Matrix(undef, 1, line_count)
    for graph_id in graph_ids
        for error in errors
            legend_labels[1, plot_line_number] = "graph: $graph_id, error: $error"
            filtered_df = filter([:error, :graph_id] => (err, id) -> err == error && id == graph_id, df)
            average_memory_lengths = zeros(length(memory_lengths))
            for (index, memory_length) in enumerate(memory_lengths)
                filtered_df_per_len = filter(:memory_length => len -> len == memory_length, filtered_df)
                average_memory_lengths[index] = mean(filtered_df_per_len.periods_elapsed)
            end
            series_matrix[:, plot_line_number] = average_memory_lengths
            plot_line_number += 1
        end
    end
    println(legend_labels)
    println(series_matrix)

    # println("plot line number: " * "$plot_line_number")

    x_label = "Memory Length"
    x_lims = (minimum(memory_lengths) - 1, maximum(memory_lengths) + 1)
    x_ticks = minimum(memory_lengths) - 1:1:maximum(memory_lengths) + 1

    sim_plot = plot(memory_lengths,
                    series_matrix,
                    label = legend_labels,
                    xlabel = x_label,
                    xlims = x_lims,
                    xticks = x_ticks,
                    ylabel = "Transition Time",
                    yscale = :log10,
                    legend_position = :topleft,
                    linestyle = :solid,
                    markershape = :circle)

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