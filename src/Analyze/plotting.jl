make_label(val) = join(uppercasefirst.(split(string(val), "_")), " ")


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
    all_params = [:graphmodel_id, :number_agents, :memory_length, :error, :starting_condition, :stopping_condition] #NOTE: might need to be :graphmodel_type here instead?

    !isempty(legend_labels) && @assert length(legend_labels) == length(qps) "legend_labels must have one entry for each QueryParams instance" #NOTE: vague
    if !isempty(colors)
        @assert length(colors) == length(qps) "colors must have one entry for each QueryParams instance" #NOTE: vague
    else
        @assert length(qps) <= 16 "cannot add more than 16 lines unless colors are specified" #NOTE: stupid limit, but will break since palette only has 16 colors
        colors = palette(:default)[1:length(qps)]
    end

    #create plot
    if isnothing(sim_plot)
        sim_plot = plot(;xlabel=make_label(sweep_parameter),
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





function two_parameter_sweep_heatmap(x_sweep_parameter::Symbol, y_sweep_parameter::Symbol, qp::Database.Query_simulations;
                                     db_info::Database.DBInfo=SETTINGS.database,
                                     statistic::Symbol=:mean,
                                     x_sweep_parameter_label::String=make_label(x_sweep_parameter),
                                     y_sweep_parameter_label::String=make_label(y_sweep_parameter),
                                     bootstrap_samples::Integer=1000,
                                     filename::String="",
                                     plot_kwargs...)
    sweep_options = (:error, :λ)
    @assert x_sweep_parameter in sweep_options
    @assert y_sweep_parameter in sweep_options
    @assert x_sweep_parameter != y_sweep_parameter
    @assert statistic in (:mean, :median) "statistic must be either :mean or :median"
    #NOTE: needs more validation (currently no validation for 1 graphmodel (plot_grouping))

    query::DataFrame = Database.db_query(db_info, qp)

    x = string.(sort(getfield(Database, x_sweep_parameter)(qp)))
    y = string.(sort(getfield(Database, y_sweep_parameter)(qp)))
    average_transition_times = Vector{Float64}()
    for sweep_group in groupby(query, [x_sweep_parameter, y_sweep_parameter], sort=true) #y_sweep_parameter rises first in the sort
        # push!(average_transition_times, mean(straps(bootstrap(mean, sweep_group.period, BasicSampling(bootstrap_samples)), 1))) #Gives the mean of the bootstrapped samples #NOTE: do we want median or mean???
        push!(average_transition_times, getfield(Statistics, statistic)(sweep_group.period))
    end
    z_data = reshape(average_transition_times, length(y), length(x)) #y rows, x columns

    full_plot = heatmap(x, y, z_data;
                        c=:viridis,
                        clims=extrema(z_data),
                        colorbar_scale=:log10,
                        xlabel=x_sweep_parameter_label,
                        ylabel=y_sweep_parameter_label,
                        xticks=true, #could be a better default
                        plot_kwargs...)

    !isempty(filename) && png(full_plot, normpath(joinpath(SETTINGS.figure_dirpath, filename)))
    return full_plot
end




"""
    function multiple_two_parameter_sweep_heatmap(db_info::Database.DBInfo=SETTINGS.database;
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
function multiple_two_parameter_sweep_heatmap(plot_grouping::Union{Symbol, Vector{Symbol}}, x_sweep_parameter::Symbol, y_sweep_parameter::Symbol, qp::Database.Query_simulations;
                                db_info::Database.DBInfo=SETTINGS.database,
                                statistic::Symbol=:mean,
                                x_sweep_parameter_label::String=make_label(x_sweep_parameter),
                                y_sweep_parameter_label::String=make_label(y_sweep_parameter),
                                subplot_titles::Vector = [],
                                colors::Vector = [],
                                error_styles::Vector = [],
                                # plot_title::String="", 
                                bootstrap_samples::Integer=1000,
                                filename::String="",
                                plot_kwargs...
)

    sweep_options = (:error, :λ)
    @assert x_sweep_parameter in sweep_options
    @assert y_sweep_parameter in sweep_options
    @assert x_sweep_parameter != y_sweep_parameter

    @assert statistic in (:mean, :median) "statistic must be either :mean or :median"

    # sort!(subplot_titles) #NOTE: not sure if i should do this


    query::DataFrame = Database.db_query(db_info, qp)
    # return query

    x = string.(sort(getfield(Database, x_sweep_parameter)(qp)))
    y = string.(sort(getfield(Database, y_sweep_parameter)(qp)))
    z_data = []
    for plot_group in groupby(query, plot_grouping, sort=true) #NOTE: alphabetical order (we probably want graphs to show up in the order that they're entered in Query_simulations, but whatever for now)
    # for gm in Database.graphmodels(qp)
        # plot_group = filter(:graphmodel_type => t -> t == Database.type(gm), query) #this method allows for ordering by graphmodel type defined in Query_graphmodels
        average_transition_times = Vector{Float64}()
        for sweep_group in groupby(plot_group, [x_sweep_parameter, y_sweep_parameter], sort=true) #y_sweep_parameter rises first in the sort
            # push!(average_transition_times, mean(straps(bootstrap(mean, sweep_group.period, BasicSampling(bootstrap_samples)), 1))) #Gives the mean of the bootstrapped samples #NOTE: do we want median or mean???
            push!(average_transition_times, getfield(Statistics, statistic)(sweep_group.period))
        end
        push!(z_data, reshape(average_transition_times, length(y), length(x))) #y rows, x columns
    end


    !isempty(subplot_titles) && @assert length(subplot_titles) == length(z_data) "subplot_titles must have one entry for each plot group specified" #NOTE: vague


    #NOTE: could probably make this more efficient
    clims_colorbar = extrema(reduce(hcat, z_data)) #first get the extrema of the original data for the colorbar scale
    z_data = map(z->log10.(z), z_data) #then take the log of the data
    clims = extrema(reduce(hcat, z_data)) #then get the extrema of the log of data for the heatmap colors

    plots = []
    for (i, z) in enumerate(z_data)
        push!(plots, heatmap(x, y, z, clims=clims, c=:viridis, colorbar=false, title=(!isempty(subplot_titles) ? subplot_titles[i] : ""), xlabel=(i == lastindex(z_data) ? x_sweep_parameter_label : ""), ylabel=y_sweep_parameter_label, xticks=true))
    end

    l = @layout [Plots.grid(length(plots), 1) a{0.01w}]

    push!(plots, scatter([0,0], [0,1], zcolor=[0,3], clims=clims_colorbar, xlims=(1,1.1), xshowaxis=false, yshowaxis=false, label="", c=:viridis, colorbar_scale=:log10, colorbar_title="Periods Elapsed", grid=false))

    full_plot = plot(plots..., layout=l, link=:all; plot_kwargs...)

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