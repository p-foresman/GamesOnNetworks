using GamesOnNetworks


function fractious_starting_condition(model::SimModel, agentgraph::AgentGraph)
    for (vertex, agent) in enumerate(agents(agentgraph))
        if vertex % 2 == 0
            recollection = strategies(model, 1)[1] #MADE THESE ALL STRATEGY 1 FOR NOW (symmetric games dont matter)
        else
            recollection = strategies(model, 1)[3]
        end
        for _ in 1:memory_length(model)
            push!(memory(agent), recollection)
        end
    end
    return nothing
end

function equity_starting_condition(model::SimModel, agentgraph::AgentGraph)
    for agent in agents(agentgraph)
        recollection = strategies(model, 1)[2]
        for _ in 1:memory_length(model)
            push!(memory(agent), recollection)
        end
    end
    return nothing
end

function random_starting_condition(model::SimModel, agentgraph::AgentGraph)
    for agent in agents(agentgraph)
        # empty!(memory(agent)) #NOTE: make sure these arent needed (shouldnt be because agentgraph is initialized with these values when state is initialized. When state is reconstructed, starting condition isn't used anyway)
        # rational_choice!(agent, Choice(0))
        # choice!(agent, Choice(0))
        for _ in 1:memory_length(model)
            push!(memory(agent), random_strategy(model, 1))
        end
    end
    return nothing
end

function equity_psychological(model::SimModel) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    sufficient_equity = (1 - error_rate(model)) * memory_length(model)
    sufficient_transitioned = number_agents(model) - number_hermits(model)
    
    return (state::State) -> begin
        number_transitioned = 0
        for agent in agents(state)
            if !ishermit(agent)
                if count_strategy(memory(agent), 2) >= sufficient_equity
                    number_transitioned += 1
                end
            end
        end 
        return number_transitioned >= sufficient_transitioned
    end
end

function equity_behavioral(model::SimModel) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    sufficient_transitioned = (1 - error_rate(model)) * (number_agents(model) - number_hermits(model))
    period_cutoff = memory_length(model)

    return (state::State) -> begin
        number_transitioned = 0
        for agent in agents(state)
            if !ishermit(agent)
                if GamesOnNetworks.rational_choice(agent) == 2 #if the agent is acting in an equitable fashion (if all agents act equitably, we can say that the behavioral equity norm is reached (ideally, there should be some time frame where all or most agents must have acted equitably))
                    number_transitioned += 1
                end
            end
        end 

        if number_transitioned >= sufficient_transitioned
            set_user_variable!(state, :period_count, user_variables(state, :period_count) + 1)
            return user_variables(state, :period_count) >= period_cutoff
        else
            set_user_variable!(state, :period_count, 0)
            return false
        end
    end
end

function period_cutoff(::SimModel)
    return (state::State) -> begin
        return period(state) >= user_variables(state, :period_cutoff) #this is hard-coded now, but should add to state extra variables or something?
    end
end

const model = SimModel(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                        SimParams(10, 10, 0.1, "fractious_starting_condition", "equity_behavioral", user_variables=UserVariables(:period_count=>0)),
                        CompleteModel())