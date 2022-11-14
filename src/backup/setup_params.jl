################### Simulation Parameters #######################

params = SimParams(
                number_agents_start = 10, #creates iterator for multi-loop simulation
                number_agents_end = 10,
                number_agents_step = 1,
                memory_length_start = 10, #creates iterator for multi-loop simulation
                memory_length_end = 10,
                memory_length_step = 1,
                memory_init_state = :fractious, #specifies initialization state. Choose between :fractious, :equity, and :custom (:custom will initialize from a separate dataframe)
                error_list = [0.1], #iterated over for multi-loop simulation
                tag1 = :red,
                tag2 = :blue,
                tag1_proportion = 1.0, #1.0 for effectively "no tags" (all agents get tag1)
                averager = 5, #determines how many runs to average over for each parameter iteration
                random_seed = 1234 #sets random number generator
                )





                

################### Define Game Payoff Matrix and Strategies #######################

payoff_matrix = [(0, 0) (0, 0) (70, 30);
                (0, 0) (50, 50) (50, 30);
                (30, 70) (30, 50) (30, 30)]

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