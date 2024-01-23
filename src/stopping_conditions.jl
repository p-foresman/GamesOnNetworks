abstract type StoppingCondition end

mutable struct EquityPsychological <: StoppingCondition
    name::String
    # game::Game
    strategy::Int8
    sufficient_equity::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?) #NOTE: REMOVE
    sufficient_transitioned::Float64


    function EquityPsychological(strategy::Integer)
        return new("equity_psychological", Int8(strategy), 0.0, 0.0)
    end
end

mutable struct EquityBehavioral <: StoppingCondition
    name::String
    # game::Game
    strategy::Int8
    sufficient_transitioned::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?) #NOTE: REMOVE
    # agent_threshold::Union{Nothing, Float64} #initialized to nothing (determine in simulation). DEFENITION: (1-error)*number_agents
    period_cutoff::Int64 #initialized to nothing (determine in simulation). DEFENITION: memory_length.
    period_count::Int64 #initialized at 0
    

    function EquityBehavioral(strategy::Integer)
        return new("equity_behavioral", Int8(strategy), 0.0, 0, 0)
    end
end

struct PeriodCutoff <: StoppingCondition
    name::String
    period_cutoff::Int128

    function PeriodCutoff(period_cutoff::Integer)
        return new("period_cutoff", period_cutoff)
    end
end