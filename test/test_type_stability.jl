using GamesOnNetworks

struct EquityPsychologicalTest <: StoppingCondition
    type::String #change to type?? or remove and use the type itself
    strategy::Int
    # sufficient_equity::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?) #NOTE: REMOVE
    # sufficient_transitioned::Float64


    function EquityPsychologicalTest(strategy::Integer)
        return new("EquityPsychologicalTest", strategy)
    end
    function EquityPsychologicalTest(::String, strategy::Integer)
        return new("EquityPsychologicalTest", strategy)
    end
end

function (stoppingcondition::EquityPsychologicalTest)(model::SimModel) #game only needed for behavioral stopping conditions. could formulate a cleaner method for stopping condition selection!!
    sufficient_equity = (1 - error_rate(model)) * memory_length(model)
    sufficient_transitioned = number_agents(model) - number_hermits(model)
    
    return (state::GamesOnNetworks.State) -> begin
        number_transitioned = 0
        for agent in agents(state)
            if !ishermit(agent)
                if count_strategy(memory(agent), stoppingcondition.strategy) >= sufficient_equity
                    number_transitioned += 1
                end
            end
        end 
        return number_transitioned >= sufficient_transitioned
    end
end

const model = SimModel(Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
                        SimParams(10, 10, 0.1, FractiousState(), EquityPsychologicalTest(2)),
                        StochasticBlockModel(3, 2, 0.5, 0.5),
                        FractiousState(),
                        EquityPsychological(2))

models = SimModels(Game{3, 3}("Bargaining Game", payoff_matrix),
SimParams(10, 10, 0.1),
CompleteModel(),
FractiousState(),
PeriodCutoff(10500000), count=5)

@code_warntype simulate(model)

# @code_warntype GamesOnNetworks._simulate_model_barrier(model, nothing)
@code_warntype GamesOnNetworks._simulate_model_barrier(model, GamesOnNetworks.SETTINGS.database)

@code_warntype GamesOnNetworks._simulate_distributed_barrier(model)

@code_warntype GamesOnNetworks._simulate_distributed_barrier(model, GamesOnNetworks.SETTINGS.database, model_id=1)



@code_warntype GamesOnNetworks.State(model) #sketch

const state = GamesOnNetworks.State(model)
@code_warntype GamesOnNetworks._simulate(model, state)
@code_warntype GamesOnNetworks._simulate(model, state, GamesOnNetworks.SETTINGS.database, model_id=1)

@code_warntype GamesOnNetworks.is_stopping_condition(state, stoppingcondition(model))

@code_warntype GamesOnNetworks.run_period!(model, state)

@code_warntype GamesOnNetworks.calculate_expected_utilities!(model, state)

@code_warntype GamesOnNetworks.payoff_matrix(model)
const g = game(model)
@code_warntype GamesOnNetworks.payoff_matrix(g)

@code_warntype(GamesOnNetworks.components(state))

@code_warntype GamesOnNetworks.make_choices!(model, state)
@code_warntype GamesOnNetworks.rational_choice!(GamesOnNetworks.players(state, 1), GamesOnNetworks.maximum_strategy(GamesOnNetworks.expected_utilities(state, 2)))
@code_warntype GamesOnNetworks.maximum_strategy(GamesOnNetworks.expected_utilities(state, 2))
@code_warntype GamesOnNetworks.players(state, 1)

function testtt(model::SimModel, state::GamesOnNetworks.State)
    GamesOnNetworks._simulate(model, state)
    GamesOnNetworks.period!(state, 0)
end

function testt(model::SimModel)
    @timeit GamesOnNetworks.to "outer" simulate(model)
end