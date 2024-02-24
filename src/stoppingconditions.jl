abstract type StoppingCondition end

mutable struct EquityPsychological <: StoppingCondition
    name::String #change to type?? or remove and use the type itself
    # game::Game
    strategy::Int8
    sufficient_equity::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?) #NOTE: REMOVE
    sufficient_transitioned::Float64


    function EquityPsychological(strategy::Integer)
        return new("equity_psychological", Int8(strategy), 0., 0.)
    end
end

mutable struct EquityBehavioral <: StoppingCondition
    name::String
    # game::Game
    strategy::Int8
    sufficient_transitioned::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?) #NOTE: REMOVE
    # agent_threshold::Union{Nothing, Float64} #initialized to nothing (determine in simulation). DEFENITION: (1-error)*number_agents
    period_cutoff::Int #initialized to nothing (determine in simulation). DEFENITION: memory_length.
    period_count::Int #initialized at 0
    

    function EquityBehavioral(strategy::Integer)
        return new("equity_behavioral", Int8(strategy), 0., 0, 0)
    end
end

struct PeriodCutoff <: StoppingCondition
    name::String
    period_cutoff::Int128

    function PeriodCutoff(period_cutoff::Integer)
        return new("period_cutoff", period_cutoff)
    end
end


##########################################
# StoppingCondition Accessors
##########################################

"""
    type(stopping_condition::StoppingCondition)

Get the stopping condition type.
"""
type(stopping_condition::StoppingCondition) = getfield(stopping_condition, :name)
strategy(stopping_condition::EquityPsychological) = getfield(stopping_condition, :strategy)
sufficient_equity(stopping_condition::EquityPsychological) = getfield(stopping_condition, :sufficient_equity)
sufficient_equity!(stopping_condition::EquityPsychological, value::Float64) = setfield!(stopping_condition, :sufficient_equity, value)
sufficient_transitioned(stopping_condition::EquityPsychological) = getfield(stopping_condition, :sufficient_transitioned)
sufficient_transitioned!(stopping_condition::EquityPsychological, value::Float64) = setfield!(stopping_condition, :sufficient_transitioned, value)


strategy(stopping_condition::EquityBehavioral) = getfield(stopping_condition, :strategy)
sufficient_transitioned(stopping_condition::EquityBehavioral) = getfield(stopping_condition, :sufficient_transitioned)
sufficient_transitioned!(stopping_condition::EquityBehavioral, value::Float64) = setfield!(stopping_condition, :sufficient_transitioned, value)
period_cutoff(stopping_condition::EquityBehavioral) = getfield(stopping_condition, :period_cutoff)
period_cutoff!(stopping_condition::EquityBehavioral, value::Int) = setfield!(stopping_condition, :period_cutoff, value)
period_count(stopping_condition::EquityBehavioral) = getfield(stopping_condition, :period_count)
period_count!(stopping_condition::EquityBehavioral, value::Int) = setfield!(stopping_condition, :period_count, value)
increment_period_count!(stopping_condition::EquityBehavioral, value::Int=1) = period_count!(stopping_condition, period_count(stopping_condition) + value)


period_cutoff(stopping_condition::PeriodCutoff) = getfield(stopping_condition, :period_cutoff)


displayname(stopping_condition::StoppingCondition) = type(stopping_condition)
Base.show(stopping_condition::StoppingCondition) = println(displayname(stopping_condition)) #make this more specific than name?