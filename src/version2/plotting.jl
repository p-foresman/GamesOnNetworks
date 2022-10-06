using Plots, GraphPlot, StatsPlots, Cairo, Fontconfig

include("database_api.jl")


#Plotting for box plot (all network classes)
function transitionTimesBoxPlot(db_grouping_id::Int)
    

    colors = [palette(:default)[11] palette(:default)[2] palette(:default)[2] palette(:default)[12] palette(:default)[9] palette(:default)[9] palette(:default)[9] palette(:default)[14]]
    x_vals = ["Complete" "ER λ=1" "ER λ=5" "SW" "SF α=2" "SF α=4" "SF α=8" "SBM"]
    sim_plot = boxplot(x_vals,
                    transition_times_matrix,
                    leg = false,
                    yscale = :log10,
                    xlabel = "Network",
                    ylabel = "Transtition Time (periods)",
                    fillcolor = colors) =#

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

df = querySimulationsForPotting(1)