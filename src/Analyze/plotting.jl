
"""
    single_parameter_sweep(sweep_parameter::Symbol, qps::Database.Query_simulations...;
                            db_info::Database.DBInfo=SETTINGS.database,
                            conf_intervals::Bool = false,
                            conf_level::AbstractFloat = 0.95,
                            bootstrap_samples::Integer = 1000,
                            legend_labels::Vector = [],
                            colors::Vector = [],
                            error_styles::Vector = [],
                            sim_plot::Union{Plots.Plot, Nothing}=nothing,
                            plot_kwargs...)

Plot the transition time vs a single parameter.
sweep_parameter options - :number_agents, :memory_length, :error
"""
function single_parameter_sweep(sweep_parameter::Symbol, qps::Database.Query_simulations...;
                            db_info::Database.DBInfo=SETTINGS.database,
                            conf_intervals::Bool = false,
                            conf_level::AbstractFloat = 0.95,
                            bootstrap_samples::Integer = 1000,
                            legend_labels::Vector = [],
                            colors::Vector = [],
                            error_styles::Vector = [],
                            sim_plot::Union{Plots.Plot, Nothing}=nothing, #to add on to a previous plot
                            plot_kwargs...
    )

    #validation
    @assert sweep_parameter in (:number_agents, :memory_length, :error) "sweep_parameter must be :number_agents, :memory_length, :error"
    all_params = [:graphmodel_id, :number_agents, :memory_length, :error, :starting_condition, :stopping_condition]

    !isempty(legend_labels) && @assert length(legend_labels) == length(qps) "legend_labels must have one entry for each QueryParams instance" #NOTE: vague
    if !isempty(colors)
        @assert length(colors) == length(qps) "colors must have one entry for each QueryParams instance" #NOTE: vague
    else
        @assert length(qps) <= 16 "cannot add more than 16 lines unless colors are specified" #NOTE: stupid limit, but will break since palette only has 16 colors
        colors = palette(:default)[1:length(qps)]
    end

    #create plot
    if isnothing(sim_plot)
        sim_plot = plot(;xlabel=join(uppercasefirst.(split(string(sweep_parameter), "_")), " "),
                        ylabel="Transition Time",
                        plot_kwargs...
        )
    end

    #make queries for each Query_simulations instance provided and plot the line based on the sweep parameter chosen
    for (i, qp) in enumerate(qps)
        sweep_param_vals = getfield(Database, sweep_parameter)(qp)

        #NOTE: ADD Query_simulations VALIDATION HERE! 

        query::DataFrame = Database.db_query(db_info, qp)

        for query_group in groupby(query, filter!(param->param!=sweep_parameter, all_params)) #NOTE: ALL OF THESE GROUPS MUST HAVE THE SAME NUMBER OF POPULATION SUB-GROUPS!!! i.e. cant create graphs with different population ranges like AEY in one go. Figure out how?
            average_transition_time = Vector{Float64}([])

            conf_interval_vals = Vector{Vector{Float64}}([[], []]) #[lower, upper]
            for population_group in groupby(query_group, sweep_parameter, sort=true)
                confidence_interval = confint(bootstrap(mean, population_group.period, BasicSampling(bootstrap_samples)), PercentileConfInt(conf_level))[1] #the first element contains the CI tuple

                push!(average_transition_time, confidence_interval[1]) #first element is the mean
                println(conf_interval_vals)
                push!(conf_interval_vals[1], confidence_interval[2])
                push!(conf_interval_vals[2], confidence_interval[3])
            end

            #NOTE: could sort at beginning
            plot!(sort(sweep_param_vals), average_transition_time, markershape=:circle, linewidth=2, label=!isempty(legend_labels) && legend_labels[i], markercolor=colors[i], linecolor=colors[i])#, linestyle=linestyles[i])
            conf_intervals && plot!(sort(sweep_param_vals), conf_interval_vals[1], fillrange=conf_interval_vals[2], linealpha=0, fillalpha=0.2, label=nothing, fillcolor=colors[i])#, fillstyle=fillstyles[i])
        end
    end
    return sim_plot
end




"""
    function noise_vs_structure_heatmap(db_info::Database.DBInfo=SETTINGS.database;
            game_id::Integer,
            graphmodel_extra::Vector{<:Dict{Symbol, Any}},
            errors::Vector{<:AbstractFloat},
            mean_degrees::Vector{<:AbstractFloat},
            number_agents::Integer,
            memory_length::Integer,
            startingcondition_id::Integer,
            stoppingcondition_id::Integer,
            sample_size::Integer,
            legend_labels::Vector = [],
            colors::Vector = [],
            error_styles::Vector = [],
            plot_title::String="", 
            bootstrap_samples::Integer=1000)

If no positional argument given, configured database is used.
"""
function noise_structure_heatmap(qp::Database.Query_simulations;
                                db_info::Database.DBInfo=SETTINGS.database,
                                sample_size::Integer,
                                legend_labels::Vector = [],
                                colors::Vector = [],
                                error_styles::Vector = [],
                                plot_title::String="", 
                                bootstrap_samples::Integer=1000,
                                filename::String="")

    # sort!(graph_ids)
    # sort!(error_rates)
    # sort!(mean_degrees)


    x = string.(mean_degrees)
    y = string.(error_rates)
    # x_axis = fill(string.(mean_degrees), (length(graph_ids), 1))
    # y_axis = fill(string.(error_rates), (length(graph_ids), 1))

    # graphmodel_list = [:λ, :β, :α, :blocks, :p_in, :p_out]
    # for graph in graphmodel
    #     for param in graphmodel_list
    #         if !(param in collect(keys(graph)))
    #             graph[param] = nothing
    #         end
    #     end
    # end
    graphmodel = Vector{Dict{Symbol, Any}}()
    for λ in mean_degrees
        for graph in graphmodel_extra
            g = deepcopy(graph)
            g[:λ] = λ
            delete!(g, :title)
            push!(graphmodel, g)
        end
    end
    println(graphmodel)

    # z_data = fill(zeros(length(mean_degrees), length(error_rates)), (1, length(graphmodel_extra)))
    # z_data = [zeros(length(mean_degrees), length(error_rates)) for _ in 1:length(graphmodel_extra)]
    z_data = zeros(length(error_rates), length(mean_degrees), length(graphmodel_extra))

    println(z_data)
    df = Database.execute_query_simulations_for_noise_structure_heatmap(db_info,
                                                                game_id=game_id,
                                                                graphmodel_params=graphmodel,
                                                                error_rates=error_rates,
                                                                mean_degrees=mean_degrees,
                                                                number_agents=number_agents,
                                                                memory_length=memory_length,
                                                                starting_condition=starting_condition,
                                                                stopping_condition=stopping_condition,
                                                                sample_size=sample_size)


    # query::DataFrame = Database.db_query(db_info, qp)
    # return df
    for (graph_index, graph) in enumerate(graphmodel_extra)

        function graph_filter(graphmodel_type, β, α, p_in, p_out)
            graphmodel_type_match = graphmodel_type == graph[:type]
            β_match = haskey(graph, :β) ? β == graph[:β] : ismissing(β)
            α_match = haskey(graph, :α) ? α == graph[:α] : ismissing(α)
            p_in_match = haskey(graph, :p_in) ? p_in == graph[:p_in] : ismissing(p_in)
            p_out_match = haskey(graph, :p_out) ? p_out == graph[:p_out] : ismissing(p_out)
            return graphmodel_type_match && β_match && α_match && p_in_match && p_out_match
        end

        filtered_df = filter([:graphmodel_type, :β, :α, :p_in, :p_out] => graph_filter, df) #NOTE: this is filtering by graph graphmodel_type only, which is okay if there's only one of each graph type. Otherwise, need to change!!!
        # println(filtered_df)
        for (col, mean_degree) in enumerate(mean_degrees)
            for (row, error) in enumerate(error_rates)
            more_filtered = filter([:error, :λ] => (err, λ) -> err == error && λ == mean_degree, filtered_df)
            println(more_filtered)
            # scaled_period = more_filtered.period ./ GraphsExt.edge_density(number_agents, mean_degree) #NOTE: REMOVE THIS]
            # scaled_period = more_filtered.period
            scaled_period = (more_filtered.period .* GraphsExt.edge_density(number_agents, mean_degree) .* number_agents) / 2
            average_transition_time = mean(straps(bootstrap(mean, scaled_period, BasicSampling(bootstrap_samples)), 1)) #Gives the mean of the bootstrapped samples
            # average_transition_time = mean(more_filtered.period)
            println(average_transition_time)
            println("($row, $col, $graph_index)")
            z_data[row, col, graph_index] = average_transition_time
            println(log10(average_transition_time))
            end
        end
    end

    for i in eachindex(graphmodel_extra)
        println(z_data[:, :, i])
    end

    #this stuff needs to be removed!
    # z_data = [zeros(length(mean_degrees), length(error_rates)) for _ in 1:length(graphmodel_extra)]
    # z_data = zeros(length(mean_degrees), length(error_rates), length(graphmodel_extra))
    # for i in eachindex(graphmodel_extra)
    #     for x in eachindex(mean_degrees)
    #         for y in eachindex(error_rates)
    #             z_data[i, x, y] = i + x + y
    #         end
    #     end
    # end
    # println(z_data)
    # return z_data
    clims_colorbar = extrema(z_data) #first get the extrema of the original data for the colorbar scale
    z_data = log10.(z_data) #then take the log of the data
    clims = extrema(z_data) #then get the extrema of the log of data for the heatmap colors
    # clims = (log10(10), log10(100000))
    println(clims)

    plots = []
    # for z in z_data
    #     println(z)
    #     push!(plots, heatmap(x, y, z, clims=clims, c=:viridis, colorbar=false))
    # end
    for graph_index in eachindex(graphmodel_extra)
        println(z_data[:, :, graph_index])
        title = "\n" * graphmodel_extra[graph_index][:title]
        # x_ticks = graph_index == length(graphmodel_extra)
        # x_label = x_ticks ? "Mean Degree" : ""
        x_ticks = true
        x_label = graph_index == length(graphmodel_extra) ? "Mean Degree" : ""
        push!(plots, heatmap(x, y, z_data[:, :, graph_index], clims=clims, c=:viridis, colorbar=false, title=title, xlabel=x_label, ylabel="Error", xticks=x_ticks))
    end

    push!(plots, scatter([0,0], [0,1], zcolor=[0,3], clims=clims_colorbar,
    xlims=(1,1.1), xshowaxis=false, yshowaxis=false, label="", c=:viridis, colorbar_scale=:log10, colorbar_title="Periods Elapsed", grid=false))

    # l = @layout [Plots.grid(length(z_data), 1) a{0.01w}]
    l = @layout [Plots.grid(length(graphmodel_extra), 1) a{0.01w}]
    full_plot = plot(plots..., layout=l, link=:all, size=(1000, 1000), left_margin=10Plots.mm, right_margin=10Plots.mm)
    # savefig(p_all, "shared_colorbar_julia.png")
    !isempty(filename) && png(full_plot, normpath(joinpath(SETTINGS.figure_dirpath, filename)))
    return full_plot
end







function time_series_plot(db_filepath::String; sim_group_id::Integer, plot_title::String = "")
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
# agent_memory = agent.memory
# agent_behavior = determineAgentBehavior(reproduced_game, agent_memory) #old
push!(agent_dict[row.periods_elapsed], rational_choice(agent))
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


#NOTE: CORRECT FOR HERMITS!! AND CUT OFF BEGINNING (period 0 isn't stored, but should be)!
function multiple_time_series_plot(db_filepath::String; sim_group_ids::Vector{<:Integer}, labels::Union{Vector{String}, Nothing} = nothing, plot_title::String = "")
time_series_plot = plot(
ylims=(0.0, 1.0),
layout=(3, 1),
legend=[true false false],
title=[plot_title "" ""], 
xlabel=["" "" "Periods Elapsed"],
xticks=[:none :none :auto],
ylabel=["Proportion H" "Proportion M" "Proportion L"],
size=(1000, 1500))
for (i, sim_group_id) in enumerate(sim_group_ids)
sim_info_df, agent_df = querySimulationsForTimeSeries(db_filepath, sim_group_id=sim_group_id)
payoff_matrix_size = JSON3.read(sim_info_df[1, :payoff_matrix_size], Tuple)
payoff_matrix_length = payoff_matrix_size[1] * payoff_matrix_size[2]
# reproduced_game = JSON3.read(sim_info_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], payoff_matrix_length})
agent_dict = OrderedDict()
hermit_count = 0
for (row_num, row) in enumerate(eachrow(agent_df))
if !haskey(agent_dict, row.periods_elapsed)
agent_dict[row.periods_elapsed] = []
end
agent = JSON3.read(row.agent, Agent)
# agent_memory = agent.memory
# agent_behavior = determineAgentBehavior(reproduced_game, agent_memory) #old
if !ishermit(agent) #if the agent is a hermit, it shouldn't count in the population
push!(agent_dict[row.periods_elapsed], rational_choice(agent))
else
if row_num == 1
hermit_count += 1
end
end
end
period_counts = Vector()
fraction_L = Vector()
fraction_M = Vector()
fraction_H = Vector()
# fractions = Vector()
for (periods_elapsed, agent_behaviors) in agent_dict
push!(period_counts, periods_elapsed)
# subfractions = Vector()
push!(fraction_L, count(action->(action==3), agent_behaviors) / (sim_info_df[1, :number_agents] - hermit_count))
push!(fraction_M, count(action->(action==2), agent_behaviors) / (sim_info_df[1, :number_agents] - hermit_count))
push!(fraction_H, count(action->(action==1), agent_behaviors) / (sim_info_df[1, :number_agents] - hermit_count))
# println("$periods_elapsed: $subfractions")
# push!(fractions, subfractions)
end
label = labels !== nothing ? labels[i] : nothing
time_series_plot = plot!(period_counts,
    [fraction_H fraction_M fraction_L],
    label=label,
    linewidth=2)
end
return time_series_plot
end














#NOTE: the following 3 can likely be merged into 1


#Plotting for box plot (all network classes)
function single_parameter_group_boxplot(db_filepath::String;
    game_id::Integer,
    number_agents::Integer,
    memory_length::Integer,
    error::Float64,
    graph_ids::Union{Vector{<:Integer}, Nothing} = nothing,
    x_labels,
    colors,
    sample_size::Integer
)
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
function single_parameter_group_violin(db_filepath::String; game_id::Integer, number_agents::Integer, memory_length::Integer, error::Float64, graph_ids::Union{Vector{<:Integer}, Nothing} = nothing, x_labels, colors, sample_size::Integer)
df = Database.querySimulationsForBoxPlot(db_filepath, game_id=game_id, number_agents=number_agents, memory_length=memory_length, error=error, graph_ids=graph_ids, sample_size=sample_size)
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
function transitionTimesBoxPlot_popsweep(db_filepath::String; game_id::Integer, graph_id::Integer, memory_length::Integer, number_agents::Union{Vector{<:Integer}, Nothing} = nothing, error::Float64, x_labels, colors, sample_size::Integer)
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