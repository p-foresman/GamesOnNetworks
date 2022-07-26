################### Simulation Parameters #######################
number_agents = 10
matches_per_period = floor(number_agents / 2)
memory_length = 10
error = 0.10
tag_proportion = 1.0 #1.0 for effectively "no tags" (all agents get tag1)
sufficient_equity = (1 - error) * memory_length #can you instantiate this with struct function?
#number_periods = 80
tag1 = "red" #not used yet
tag2 = "blue" #not used yet
m_init = "fractious" #specifies initialization state
iterationParam = :memorylength #can be :memorylength or :numberagents
iterator = 10:1:10 #7:3:19 #determines the values of the indepent variable (right now set for one iteration (memory lenght 10))
error_list = [0.1]
averager = 5

params = SimParams(number_agents,
                memory_length,
                error,
                matches_per_period,
                tag_proportion,
                sufficient_equity,
                tag1,
                tag2,
                m_init,
                iterationParam,
                iterator,
                error_list,
                averager)




################### Define Game Payoff Matrix and Strategies #######################
payoff_matrix = [(0, 0) (0, 0) (70, 30);
                (0, 0) (50, 50) (50, 30);
                (30, 70) (30, 50) (30, 30)]
strategies = [1, 2, 3] #corresponds to [High, Medium, Low]

#create bargaining game type (players will be slotted in)
game = Game("Bargaining Game", payoff_matrix, strategies)




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