function find_threshold(db_filepath::String; sim_group_id::Integer)
    sim_info_df, agent_df = querySimulationsForTimeSeries(db_filepath, sim_group_id=sim_group_id)
    payoff_matrix_size = JSON3.read(sim_info_df[1, :payoff_matrix_size], Tuple)
    payoff_matrix_length = payoff_matrix_size[1] * payoff_matrix_size[2]
    # reproduced_game = JSON3.read(sim_info_df[1, :game], Game{payoff_matrix_size[1], payoff_matrix_size[2], payoff_matrix_length})
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
    threshold = 0.0
    last_fraction_m = 0.0
    for (periods_elapsed, agent_behaviors) in agent_dict
        push!(period_counts, periods_elapsed)
        # subfractions = Vector()
        fraction_m = count(action->(action==2), agent_behaviors) / sim_info_df[1, :number_agents]
        push!(fraction_L, count(action->(action==3), agent_behaviors) / sim_info_df[1, :number_agents])
        push!(fraction_M, fraction_m)
        push!(fraction_H, count(action->(action==1), agent_behaviors) / sim_info_df[1, :number_agents])
        if fraction_m < last_fraction_m && last_fraction_m > threshold
            peaks = last_fraction_m
        end
        last_fraction_m = fraction_m

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