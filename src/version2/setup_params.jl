################### Simulation Parameters #######################



function constructParamsList(;number_agents_start::Int64, number_agents_end::Int64, number_agents_step::Int64, memory_length_start::Int64, memory_length_end::Int64, memory_length_step::Int64, memory_init_state::Symbol, error_list::Vector{Float64}, tag1::Symbol, tag2::Symbol, tag1_proportion::Float64, random_seed::Int64)
    params_list = Vector{SimParams}([])
    for number_agents in number_agents_start:number_agents_step:number_agents_end
        for memory_length in memory_length_start:memory_length_step:memory_length_end
            for error in error_list
                new_params_set = SimParams(number_agents=number_agents, memory_length=memory_length, memory_init_state=memory_init_state, error=error, tag1=tag1, tag2=tag2, tag1_proportion=tag1_proportion, random_seed=random_seed)
                push!(params_list, new_params_set)
            end
        end
    end
    return params_list
end

params_list = constructParamsList(
                number_agents_start = 10, #creates iterator for multi-loop simulation
                number_agents_end = 12,
                number_agents_step = 2,
                memory_length_start = 10, #creates iterator for multi-loop simulation
                memory_length_end = 12,
                memory_length_step = 2,
                memory_init_state = :fractious, #specifies initialization state. Choose between :fractious, :equity, and :custom (:custom will initialize from a separate dataframe)
                error_list = [0.1], #iterated over for multi-loop simulation
                tag1 = :red,
                tag2 = :blue,
                tag1_proportion = 1.0, #1.0 for effectively "no tags" (all agents get tag1)
                random_seed = 1234 #sets random number generator
                )

                

################### Define Game Payoff Matrix and Strategies #######################

payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                        (0, 0) (50, 50) (50, 30);
                                        (30, 70) (30, 50) (30, 30)])

#create bargaining game type (players will be slotted in)
game = Game("Bargaining Game", payoff_matrix)




################### Define Which Graph Types to Iterate Through #######################

#=
Create a vector of dictionaries containing various parameter values for graphs to be simulated over.
Use symbols (:symbol) as dictionary keys. Arrow brackets (< >) contain fields to fill in.

Graph types available with relevant parameters:
    Complete Graph: Dict(:type => "complete", :plot_label => "<label>", :line_color => :<color>)
    Erdos-Renyi Random Graph: Dict(:type => "er", :λ => <integer: λ value>, :plot_label => "<label>", :line_color => <color>)
    Watts-Strogatz Small-World Network: Dict(:type => "sw", :k => <integer: expected degree>, :β => <edge probability>, :plot_label => "<label>", :line_color => :<color>)
    Scale-Free Network (currently NOT Barabasi-Albert): Dict(:type => "sf", :α => <integer: α value (power law exponent)>, :plot_label => "<label>", :line_color => :<color>)
    Stochastic Block Model: Dict(:type => "sbm", :communities => <integer: number of communities>, :internal_λ => <integer: λ value for intra-community>, :external_λ => <integer: λ value for inter-community>, :plot_label => "<label>", :line_color => :<color>)
=#

graph_simulations_list = [
    Dict(:type => :complete, :plot_label => "Complete", :line_color => :red),
    Dict(:type => :er, :λ => 1, :plot_label => "ER λ=1", :line_color => :blue),
    Dict(:type => :er, :λ => 5, :plot_label => "ER λ=5", :line_color => :blue),
    Dict(:type => :sw, :k => 4, :β => 0.6, :plot_label => "SW k=4", :line_color => :red),
    Dict(:type => :sf, :α => 2, :plot_label => "SF α=2", :line_color => :red),
    Dict(:type => :sf, :α => 4, :plot_label => "SF α=4", :line_color => :blue),
    Dict(:type => :sf, :α => 8, :plot_label => "SF α=8", :line_color => :green),
    Dict(:type => :sbm, :communities => 2, :internal_λ => 5, :external_λ => 0.5, :plot_label => "SBM", :line_color => :green),
    ] #number_agents already defined