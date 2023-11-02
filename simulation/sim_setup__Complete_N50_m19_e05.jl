################### Define Game Payoff Matrix and Strategies #######################

const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])
#Check "global_StructTypes.jl" file and ensure that the size of this payoff matrix is listed under the "Game type" section

# s1 = size(payoff_matrix, 1)
# s2 = size(payoff_matrix, 2)

#create bargaining game type (players will be slotted in)
const game = Game{3, 3}("Bargaining Game", payoff_matrix) # would game::Game{s1, s2} improve performance?



const sim_params = SimParams(50, 19, 0.05)



################### Define Which Graph Types to Iterate Through #######################

#=
Graph types available with relevant type constructors and parameters (structs found in types.jl):
    Complete Graph: CompleteParams()
    Erdos-Renyi Random Graph: ErdosRenyiParams(λ)
    Watts-Strogatz Small-World Network: SmallWorldParams(κ, β)
    Scale-Free Network (currently NOT Barabasi-Albert): ScaleFreeParams(α)
    Stochastic Block Model: StochasticBlockModelParams(communities, internal_λ, external_λ)
=#

const graph_params = CompleteParams()

const starting_condition = FractiousState()
const stopping_condition = EquityBehavioral(2)