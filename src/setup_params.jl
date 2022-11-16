################### Simulation Parameters #######################

function getSetupParams()
    function constructSimParamsList(;number_agents_start::Int64, number_agents_end::Int64, number_agents_step::Int64, memory_length_start::Int64, memory_length_end::Int64, memory_length_step::Int64, memory_init_state::Symbol, error_list::Vector{Float64}, tag1::Symbol, tag2::Symbol, tag1_proportion::Float64, random_seed::Int64)
        sim_params_list = Vector{SimParams}([])
        for number_agents in number_agents_start:number_agents_step:number_agents_end
            for memory_length in memory_length_start:memory_length_step:memory_length_end
                for error in error_list
                    new_sim_params_set = SimParams(number_agents=number_agents, memory_length=memory_length, memory_init_state=memory_init_state, error=error, tag1=tag1, tag2=tag2, tag1_proportion=tag1_proportion, random_seed=random_seed)
                    push!(sim_params_list, new_sim_params_set)
                end
            end
        end
        return sim_params_list
    end

    sim_params_list = constructSimParamsList(
                    number_agents_start = 100, #creates iterator for multi-loop simulation
                    number_agents_end = 100,
                    number_agents_step = 1,
                    memory_length_start = 10, #creates iterator for multi-loop simulation
                    memory_length_end = 10,
                    memory_length_step = 1,
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
    #Check "global_StructTypes.jl" file and ensure that the size of this payoff matrix is listed under the "Game type" section

    # s1 = size(payoff_matrix, 1)
    # s2 = size(payoff_matrix, 2)

    #create bargaining game type (players will be slotted in)
    game = Game("Bargaining Game", payoff_matrix) # would game::Game{s1, s2} improve performance?



    ################### Define Which Graph Types to Iterate Through #######################

    #=
    Graph types available with relevant type constructors and parameters (structs found in types.jl):
        Complete Graph: CompleteParams()
        Erdos-Renyi Random Graph: ErdosRenyiParams(λ)
        Watts-Strogatz Small-World Network: SmallWorldParams(κ, β)
        Scale-Free Network (currently NOT Barabasi-Albert): ScaleFreeParams(α)
        Stochastic Block Model: StochasticBlockModelParams(communities, internal_λ, external_λ)
    =#

    graph_params_list = (
        CompleteParams(),
        # ErdosRenyiParams(1.0),
        # ErdosRenyiParams(5.0),
        # SmallWorldParams(4, 0.6),
        # ScaleFreeParams(2.0),
        # ScaleFreeParams(4.0),
        # ScaleFreeParams(8.0),
        # StochasticBlockModelParams(2, 5.0, 0.5),
    )
    return game, sim_params_list, graph_params_list
end