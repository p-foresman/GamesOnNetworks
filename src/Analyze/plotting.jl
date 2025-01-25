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

        df = Database.db_query(db_info, qp)

        for df_group in groupby(df, filter!(param->param!=sweep_parameter, all_params)) #NOTE: ALL OF THESE GROUPS MUST HAVE THE SAME NUMBER OF POPULATION SUB-GROUPS!!! i.e. cant create graphs with different population ranges like AEY in one go. Figure out how?
            average_transition_time = Vector{Float64}([])

            conf_interval_vals = Vector{Vector{Float64}}([[], []]) #[lower, upper]
            for population_group in groupby(df_group, sweep_parameter, sort=true)
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