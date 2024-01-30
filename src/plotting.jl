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
                    fillcolor = colors,
                    size=(1800, 700),
                    left_margin=10Plots.mm,
                    right_margin=10Plots.mm,
                    bottom_margin=10Plots.mm)

    return sim_plot
end


#Plotting for violin plot (all network classes)
function transitionTimesViolinPlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length::Integer, error::Float64, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, x_labels, colors, sample_size::Integer)
    df = querySimulationsForBoxPlot(db_filepath, game_id=game_id, number_agents=number_agents, memory_length=memory_length, error=error, graph_ids=graph_ids, sample_size=sample_size)
    transition_times_matrix = zeros(sample_size, length(graph_ids))
    println(df)
    for (graph_number, graph_id) in enumerate(graph_ids)
        filtered_df = filter(:graph_id => id -> id == graph_id, df)
        transition_times_matrix[:, graph_number] = filtered_df[:, :periods_elapsed]
    end
    # colors = [palette(:default)[11] palette(:default)[2] palette(:default)[2]] #palette(:default)[12] palette(:default)[9] palette(:default)[9] palette(:default)[9] palette(:default)[14]
    # x_vals = ["Complete" "ER λ=1" "ER λ=5"] #"SW" "SF α=2" "SF α=4" "SF α=8" "SBM"
    sim_plot = violin(x_labels,
                    transition_times_matrix,
                    leg = false,
                    yscale = :log10,
                    xlabel = "Graph",
                    ylabel = "Transtition Time (periods)",
                    fillcolor = colors,
                    size=(1800, 700),
                    left_margin=10Plots.mm,
                    right_margin=10Plots.mm,
                    bottom_margin=10Plots.mm)
    
    boxplot!(x_labels, transition_times_matrix, fillcolor=palette(:default)[5], fillalpha=0.4)
    dotplot!(x_labels, transition_times_matrix, markercolor=:black)

    return sim_plot
end


#Plotting for violin plot (all network classes)
function transitionTimesBoxPlot_populationSweep(db_filepath::String; game_id::Integer, graph_id::Integer, memory_length::Integer, number_agents::Union{Vector{<:Integer}, Nothing} = nothing, error::Float64, x_labels, colors, sample_size::Integer)
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
                    fillcolor = colors,
                    size=(1800, 700),
                    left_margin=10Plots.mm,
                    right_margin=10Plots.mm,
                    bottom_margin=10Plots.mm)

    return sim_plot
end



function memoryLengthTransitionTimeLinePlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer, conf_intervals::Bool = false, conf_level::AbstractFloat = 0.95, bootstrap_samples::Integer = 1000, legend_labels::Vector = [], colors::Vector = [], error_styles::Vector = [], plot_title::String=nothing)
    memory_length_list !== nothing ? memory_length_list = sort(memory_length_list) : nothing
    errors !== nothing ? errors = sort(errors) : nothing
    graph_ids !== nothing ? graph_ids = sort(graph_ids) : nothing

    #initialize plot
    x_label = "Memory Length"
    x_lims = (minimum(memory_length_list) - 1, maximum(memory_length_list) + 1)
    x_ticks = minimum(memory_length_list) - 1:1:maximum(memory_length_list) + 1

    legend_labels_map = Dict()
    for (index, graph_id) in enumerate(graph_ids)
        legend_labels_map[graph_id] = legend_labels[index]
    end

    colors_map = Dict()
    for (index, graph_id) in enumerate(graph_ids)
        colors_map[graph_id] = colors[index]
    end

    error_styles_map = Dict()
    for (index, error) in enumerate(errors)
        error_styles_map[error] = error_styles[index]
    end

    sim_plot = plot(xlabel = x_label,
                    xlims = x_lims,
                    xticks = x_ticks,
                    ylabel = "Transition Time",
                    yscale = :log10,
                    legend_position = :outertopright,
                    size=(1300, 700),
                    left_margin=10Plots.mm,
                    bottom_margin=10Plots.mm,
                    title=plot_title)
    

    #wrangle data
    df = querySimulationsForMemoryLengthLinePlot(db_filepath, game_id=game_id, number_agents=number_agents, memory_length_list=memory_length_list, errors=errors, graph_ids=graph_ids, sample_size=sample_size)
    plot_line_number = 1 #this will make the lines unordered***
    graph_id_number = 1
    for graph_id in graph_ids
        error_number = 1
        for error in errors
            filtered_df = filter([:error, :graph_id] => (err, id) -> err == error && id == graph_id, df)

            average_memory_lengths = Vector{Float64}([])

            conf_intervals ? confidence_interval_lower = Vector{Float64}([]) : nothing
            conf_intervals ? confidence_interval_upper = Vector{Float64}([]) : nothing
            for (index, memory_length) in enumerate(memory_length_list)
                filtered_df_per_len = filter(:memory_length => len -> len == memory_length, filtered_df)

                confidence_interval = confint(bootstrap(mean, filtered_df_per_len.periods_elapsed, BasicSampling(bootstrap_samples)), PercentileConfInt(conf_level))[1] #the first element contains the CI tuple
                
                push!(average_memory_lengths, confidence_interval[1]) #first element is the mean
                push!(confidence_interval_lower, confidence_interval[2])
                push!(confidence_interval_upper, confidence_interval[3])
            end

            # error_number == 1 ? legend_label = legend_labels_map[graph_id] : legend_label = nothing
            legend_label = "$(legend_labels_map[graph_id]), error=$error"

            plot!(memory_length_list, average_memory_lengths, markershape = :circle, markercolor=colors_map[graph_id], linecolor=colors_map[graph_id], linestyle=error_styles_map[error][1], label=legend_label)

            if conf_intervals
                plot!(memory_length_list, confidence_interval_lower, fillrange=confidence_interval_upper, linealpha=0, fillalpha=0.2, fillcolor=colors_map[graph_id], fillstyle=error_styles_map[error][2], label=nothing)
            end

            plot_line_number += 1
            error_number += 1
        end
        graph_id_number += 1
    end
    return sim_plot
end




function numberAgentsTransitionTimeLinePlot(db_filepath::String; game_id::Integer, number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing, memory_length::Integer, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer, conf_intervals::Bool = false, conf_level::AbstractFloat = 0.95, bootstrap_samples::Integer = 1000, legend_labels::Vector = [], colors::Vector = [], error_styles::Vector = [], plot_title::String=nothing)
    number_agents_list !== nothing ? number_agents_list = sort(number_agents_list) : nothing
    errors !== nothing ? errors = sort(errors) : nothing
    graph_ids !== nothing ? graph_ids = sort(graph_ids) : nothing
    

    #initialize plot
    x_label = "Number Agents"
    x_lims = (minimum(number_agents_list) - 10, maximum(number_agents_list) + 10)
    x_ticks = minimum(number_agents_list) - 10:10:maximum(number_agents_list) + 10

    legend_labels_map = Dict()
    for (index, graph_id) in enumerate(graph_ids)
        legend_labels_map[graph_id] = legend_labels[index]
    end

    colors_map = Dict()
    for (index, graph_id) in enumerate(graph_ids)
        colors_map[graph_id] = colors[index]
    end

    error_styles_map = Dict()
    for (index, error) in enumerate(errors)
        error_styles_map[error] = error_styles[index]
    end

    sim_plot = plot(xlabel = x_label,
                    xlims = x_lims,
                    xticks = x_ticks,
                    ylabel = "Transition Time",
                    yscale = :log10,
                    legend_position = :outertopright,
                    size=(1300, 700),
                    left_margin=10Plots.mm,
                    bottom_margin=10Plots.mm,
                    title=plot_title)


    #wrangle data
    df = querySimulationsForNumberAgentsLinePlot(db_filepath, game_id=game_id, number_agents_list=number_agents_list, memory_length=memory_length, errors=errors, graph_ids=graph_ids, sample_size=sample_size)
    plot_line_number = 1 #this will make the lines unordered***
    for graph_id in graph_ids
        for error in errors
            filtered_df = filter([:error, :graph_id] => (err, id) -> err == error && id == graph_id, df)

            average_number_agents = Vector{Float64}([])

            conf_intervals ? confidence_interval_lower = Vector{Float64}([]) : nothing
            conf_intervals ? confidence_interval_upper = Vector{Float64}([]) : nothing
            for (index, number_agents) in enumerate(number_agents_list)
                filtered_df_per_num = filter(:number_agents => num -> num == number_agents, filtered_df)

                confidence_interval = confint(bootstrap(mean, filtered_df_per_num.periods_elapsed, BasicSampling(bootstrap_samples)), PercentileConfInt(conf_level))[1] #the first element contains the CI tuple

                push!(average_number_agents, confidence_interval[1]) #first element is the mean
                push!(confidence_interval_lower, confidence_interval[2])
                push!(confidence_interval_upper, confidence_interval[3])
            end

            legend_label = "$(legend_labels_map[graph_id]), error=$error"

            plot!(number_agents_list, average_number_agents, markershape = :circle, markercolor=colors_map[graph_id], linecolor=colors_map[graph_id], linestyle=error_styles_map[error][1], label=legend_label)

            if conf_intervals
                plot!(number_agents_list, confidence_interval_lower, fillrange=confidence_interval_upper, linealpha=0, fillalpha=0.2, fillcolor=colors_map[graph_id], fillstyle=error_styles_map[error][2], label=nothing)
            end

            plot_line_number += 1
        end
    end
    return sim_plot
end



function timeSeriesPlot(db_filepath::String; sim_group_id::Integer, plot_title::String = "")
    sim_info_df, agent_df = querySimulationsForTimeSeries(db_filepath, sim_group_id=sim_group_id)
    payoff_matrix_size = JSON3.read(sim_info_df[1, :payoff_matrix_size], Tuple)
    payoff_matrix_length = payoff_matrix_size[1] * payoff_matrix_size[2]
    reproduced_game = JSON3.read(sim_info_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], payoff_matrix_length})
    agent_dict = OrderedDict()
    for row in eachrow(agent_df)
        if !haskey(agent_dict, row.periods_elapsed)
            agent_dict[row.periods_elapsed] = []
        end
        agent = JSON3.read(row.agent, Agent)
        agent_memory = agent.memory
        agent_behavior = determineAgentBehavior(reproduced_game, agent_memory)
        push!(agent_dict[row.periods_elapsed], agent_behavior)
    end
    period_counts = Vector()
    fraction_L = Vector()
    fraction_M = Vector()
    fraction_H = Vector()
    # fractions = Vector()
    for (periods_elapsed, agent_behaviors) in agent_dict
        push!(period_counts, periods_elapsed)
        # subfractions = Vector()
        push!(fraction_L, count(action->(action==3), agent_behaviors) / sim_info_df[1, :number_agents])
        push!(fraction_M, count(action->(action==2), agent_behaviors) / sim_info_df[1, :number_agents])
        push!(fraction_H, count(action->(action==1), agent_behaviors) / sim_info_df[1, :number_agents])
        # println("$periods_elapsed: $subfractions")
        # push!(fractions, subfractions)
    end
    time_series_plot = plot(period_counts,
                            [fraction_H fraction_M fraction_L],
                            ylims=(0.0, 1.0),
                            layout=(3, 1),
                            legend=false,
                            title=[plot_title "" ""], 
                            xlabel=["" "" "Periods Elapsed"],
                            xticks=[:none :none :auto],
                            ylabel=["Proportion H" "Proportion M" "Proportion L"],
                            size=(700, 700))
    return time_series_plot
end



function plot_degree_distribution(g)
    hist = degree_histogram(g)
    total_vertices = nv(g)
    normalized_hist = Dict()
    for (degree, num_vertices) in hist
        normalized_hist[degree] = num_vertices/total_vertices
        # append!(x, degree)
        # append!(y, num_vertices/total_vertices)
    end
    return plot(normalized_hist)
end

function fit_degree_dist(D, g::SimpleGraph{Int})
    sample_points = degree(g)
    return fit(D, sample_points)
end

function plot_fitted_degree_dist(D, g::SimpleGraph{Int})
    fit = fit_degree_dist(D, g)
    nv = Graphs.nv(g)
    return plot(D, x_lims=[0, nv])
end




# function memoryLengthTransitionTimeLinePlot(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length_list::Union{Vector{<:Integer}, Nothing} = nothing, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
#     memory_length_list !== nothing ? memory_length_list = sort(memory_lengths) : nothing
#     errors !== nothing ? errors = sort(errors) : nothing
#     graph_ids !== nothing ? graph_ids = sort(graph_ids) : nothing
    
#     df = querySimulationsForMemoryLengthLinePlot(db_filepath, game_id=game_id, number_agents=number_agents, memory_length_list=memory_length_list, errors=errors, graph_ids=graph_ids, sample_size=sample_size)
#     println(df)
#     line_count = length(errors) * length(graph_ids)
#     println("line count: " * "$line_count")
#     series_matrix = zeros(length(memory_length_list), line_count) #this is an issue if memory_lengths/errors/graph_ids=nothing***
#     plot_line_number = 1 #this will make the lines unordered***
    
#     println(series_matrix)
#     legend_labels = Matrix(undef, 1, line_count)
#     for graph_id in graph_ids
#         for error in errors
#             legend_labels[1, plot_line_number] = "graph: $graph_id, error: $error"
#             filtered_df = filter([:error, :graph_id] => (err, id) -> err == error && id == graph_id, df)
#             average_memory_lengths = zeros(length(memory_length_list))
#             for (index, memory_length) in enumerate(memory_length_list)
#                 filtered_df_per_len = filter(:memory_length => len -> len == memory_length, filtered_df)
#                 average_memory_lengths[index] = mean(filtered_df_per_len.periods_elapsed)
#             end
#             series_matrix[:, plot_line_number] = average_memory_lengths
#             plot_line_number += 1
#         end
#     end
#     println(legend_labels)
#     println(series_matrix)

#     # println("plot line number: " * "$plot_line_number")

#     x_label = "Memory Length"
#     x_lims = (minimum(memory_length_list) - 1, maximum(memory_length_list) + 1)
#     x_ticks = minimum(memory_length_list) - 1:1:maximum(memory_length_list) + 1

#     sim_plot = plot(memory_length_list,
#                     series_matrix,
#                     label = legend_labels,
#                     xlabel = x_label,
#                     xlims = x_lims,
#                     xticks = x_ticks,
#                     ylabel = "Transition Time",
#                     yscale = :log10,
#                     legend_position = :topleft,
#                     linestyle = :solid,
#                     markershape = :circle)

#     return sim_plot
# end




# function numberAgentsTransitionTimeLinePlot(db_filepath::String; game_id::Integer, number_agents_list::Union{Vector{<:Integer}, Nothing} = nothing, memory_length::Integer, errors::Union{Vector{<:AbstractFloat}, Nothing} = nothing, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, sample_size::Integer)
#     gr()
#     number_agents_list !== nothing ? number_agents_list = sort(number_agents_list) : nothing
#     errors !== nothing ? errors = sort(errors) : nothing
#     graph_ids !== nothing ? graph_ids = sort(graph_ids) : nothing
    

#     conf_level = 0.95 #new (make this a parameter)


#     x_label = "Number Agents"
#     x_lims = (minimum(number_agents_list) - 10, maximum(number_agents_list) + 10)
#     x_ticks = minimum(number_agents_list) - 10:10:maximum(number_agents_list) + 10

#     # sim_plot = plot(xlabel = x_label,
#     #                 xlims = x_lims,
#     #                 xticks = x_ticks,
#     #                 ylabel = "Transition Time",
#     #                 yscale = :log10,
#     #                 legend_position = :outertopright)
#     sim_plot = plot()



#     df = querySimulationsForNumberAgentsLinePlot(db_filepath, game_id=game_id, number_agents_list=number_agents_list, memory_length=memory_length, errors=errors, graph_ids=graph_ids, sample_size=sample_size)
#     # println(df)
#     line_count = length(errors) * length(graph_ids)
#     println("line count: " * "$line_count")
#     series_matrix = zeros(length(number_agents_list), line_count) #this is an issue if memory_lengths/errors/graph_ids=nothing***
#     plot_line_number = 1 #this will make the lines unordered***

#     # y_lims = (0, maximum(df[:, :periods_elapsed]) + 100) #new

#     println(series_matrix)
#     legend_labels = Matrix(undef, 1, line_count)
#     for graph_id in graph_ids
#         for error in errors
#             legend_labels[1, plot_line_number] = "graph: $graph_id, error: $error"
#             filtered_df = filter([:error, :graph_id] => (err, id) -> err == error && id == graph_id, df)

#             single_series_matrix = fill(Int64(0), length(number_agents_list), sample_size) #new
#             confidence_interval_upper = Vector{Float64}([])
#             confidence_interval_lower = Vector{Float64}([])
            
#             average_number_agents = zeros(length(number_agents_list))
#             for (index, number_agents) in enumerate(number_agents_list)
#                 filtered_df_per_num = filter(:number_agents => num -> num == number_agents, filtered_df)
#                 average_number_agents[index] = mean(filtered_df_per_num.periods_elapsed)

#                 single_series_matrix[index, :] = filtered_df_per_num.periods_elapsed #new
#                 confidence_interval = confint(OneSampleTTest(filtered_df_per_num.periods_elapsed))
#                 push!(confidence_interval_lower, confidence_interval[1])
#                 push!(confidence_interval_upper, confidence_interval[2])
#                 println(single_series_matrix)
#                 println(confidence_interval_upper)
#                 println(confidence_interval_lower)

#             end
#             series_matrix[:, plot_line_number] = average_number_agents

#             if plot_line_number == 1
#                 plot!(number_agents_list,
#                             average_number_agents,
#                             label="$plot_line_number",
#                             xlabel = x_label,
#                             xlims = x_lims,
#                             xticks = x_ticks,
#                             # ylims = y_lims,
#                             ylabel = "Transition Time",
#                             yscale = :log10,
#                             legend_position = :outertopright)
#                 # errorline!(number_agents_list,
#                 #                 single_series_matrix,
#                 #                 errorstyle=:ribbon,
#                 #                 label="$plot_line_number",
#                 #                 xlabel = x_label,
#                 #                 xlims = x_lims,
#                 #                 xticks = x_ticks,
#                 #                 # ylims = y_lims,
#                 #                 ylabel = "Transition Time",
#                 #                 # yscale = :log10,
#                 #                 legend_position = :outertopright)
#             else
#                 plot!(number_agents_list,
#                 average_number_agents)
#                 # errorline!(number_agents_list, single_series_matrix, errorstyle=:ribbon)
#             end

#             plot!(number_agents_list, confidence_interval_lower, fillrange=confidence_interval_upper, linealpha=0.2, fillalpha=0.2)

#             plot_line_number += 1

#         end
#     end
#     println(legend_labels)
#     println(series_matrix)

#     # println("plot line number: " * "$plot_line_number")

#     # ribbon_vals = [[10 100 10 5000] (10, 5000) (10, 300)]
#     #  (10, 40) (10, 100) (10, 200) (10, 200) (10, 1000); (10, 200) (10, 200) (10, 1000) (10, 200) (10, 200) (10, 1000) (10, 200) (10, 200); (10, 1000) (10, 200) (10, 200) (10, 1000) (10, 200) (10, 200) (10, 1000) (10, 200)]
#     # sim_plot = plot(number_agents_list,
#     #                 series_matrix,
#     #                 ribbon = ribbon_vals,
#     #                 label = legend_labels,
#     #                 xlabel = x_label,
#     #                 xlims = x_lims,
#     #                 xticks = x_ticks,
#     #                 ylabel = "Transition Time",
#     #                 yscale = :log10,
#     #                 legend_position = :outertopright,
#     #                 linestyle = :solid,
#     #                 markershape = :circle)


#     return sim_plot
# end