"""
    StoppingCondition

An abstract type representing stopping conditions for simulations.
"""
abstract type StoppingCondition end

"""
    EquityPsychological

Type denoting the "equity psychological" stopping condition.

This stopping condition is based on a psychological perspective. If all agents have sufficient "beliefs"
that align with the equity state, the system can be said to be in the equity state.

Definition: If all agents (excluding hermits) have (1-ϵ)*m instances of the equity condition in their memories at any given
period, stop.
"""
mutable struct EquityPsychological <: StoppingCondition
    name::String #change to type?? or remove and use the type itself
    # game::Game
    strategy::Int
    sufficient_equity::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?) #NOTE: REMOVE
    sufficient_transitioned::Float64


    function EquityPsychological(strategy::Integer)
        return new("equity_psychological", strategy, 0., 0.)
    end
    function EquityPsychological(stopping_condition::EquityPsychological) #used to get a "raw" version of the stopping condition to send to the database
        return EquityPsychological(strategy(stopping_condition))
    end
end

"""
    EquityBehavioral

Type denoting the "equity behavioral" stopping condition.

This stopping condition is based on a behavioral/sociological perspective. If a big enough proportion of
agents sufficiently act in a way that aligns with an equity dynamic for long enough, the 
system can be said to be in the equity state.

Definition: If (1-ϵ)*N agents (excluding hermits) have a behavioral/rational choice that aligns
with the equity state for m number of periods in a row, stop.
"""
mutable struct EquityBehavioral <: StoppingCondition
    name::String
    # game::Game
    strategy::Int
    sufficient_transitioned::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?) #NOTE: REMOVE
    # agent_threshold::Union{Nothing, Float64} #initialized to nothing (determine in simulation). DEFINITION: (1-error)*number_agents
    period_cutoff::Int #initialized to nothing (determine in simulation). DEFINITION: memory_length.
    period_count::Int #initialized at 0
    

    function EquityBehavioral(strategy::Integer)
        return new("equity_behavioral", strategy, 0., 0, 0)
    end
    function EquityBehavioral(stopping_condition::EquityBehavioral) #used to get a "raw" version of the stopping condition to send to the database
        return EquityBehavioral(strategy(stopping_condition))
    end
end

"""
    PeriodCutoff

Type denoting the "period cutoff" stopping condition.

Definition: After a specified number of periods has passed, stop.
"""
struct PeriodCutoff <: StoppingCondition
    name::String
    period_cutoff::Int128

    function PeriodCutoff(period_cutoff::Integer)
        return new("period_cutoff", period_cutoff)
    end
    function PeriodCutoff(stopping_condition::PeriodCutoff) #used to get a "raw" version of the stopping condition to send to the database
        return PeriodCutoff(period_cutoff(stopping_condition))
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

"""
    strategy(stopping_condition::EquityPsychological)

Get the strategy that the stopping condition is targeted at.
"""
strategy(stopping_condition::EquityPsychological) = getfield(stopping_condition, :strategy)

"""
    sufficient_equity(stopping_condition::EquityPsychological)

Get the value for the sufficient number of "strategy" instances in a given agent's memory.
"""
sufficient_equity(stopping_condition::EquityPsychological) = getfield(stopping_condition, :sufficient_equity)

"""
    sufficient_equity!(stopping_condition::EquityPsychological)

Set the value for the sufficient number of "strategy" instances in a given agent's memory.
"""
sufficient_equity!(stopping_condition::EquityPsychological, value::Float64) = setfield!(stopping_condition, :sufficient_equity, value)

"""
    sufficient_transitioned(stopping_condition::EquityPsychological)

Get the value for the sufficient number of agents that must be transitioned for the simulation to stop.
"""
sufficient_transitioned(stopping_condition::EquityPsychological) = getfield(stopping_condition, :sufficient_transitioned)

"""
    sufficient_transitioned!(stopping_condition::EquityPsychological)

Set the value for the sufficient number of agents that must be transitioned for the simulation to stop.
"""
sufficient_transitioned!(stopping_condition::EquityPsychological, value::Float64) = setfield!(stopping_condition, :sufficient_transitioned, value)

"""
    strategy(stopping_condition::EquityBehavioral)

Get the strategy that the stopping condition is targeted at.
"""
strategy(stopping_condition::EquityBehavioral) = getfield(stopping_condition, :strategy)

"""
    sufficient_transitioned(stopping_condition::EquityBehavioral)

Get the value for the sufficient number of agents that must be transitioned for the period count to be incremented.
"""
sufficient_transitioned(stopping_condition::EquityBehavioral) = getfield(stopping_condition, :sufficient_transitioned)

"""
    sufficient_transitioned!(stopping_condition::EquityBehavioral)

Set the value for the sufficient number of agents that must be transitioned for the period count to be incremented.
"""
sufficient_transitioned!(stopping_condition::EquityBehavioral, value::Float64) = setfield!(stopping_condition, :sufficient_transitioned, value)

"""
    period_cutoff(stopping_condition::EquityBehavioral)

Get the number of periods required for the behavioral equity state to persist for the simulation to stop.
"""
period_cutoff(stopping_condition::EquityBehavioral) = getfield(stopping_condition, :period_cutoff)

"""
    period_cutoff!(stopping_condition::EquityBehavioral)

Set the number of periods required for the behavioral equity state to persist for the simulation to stop.
"""
period_cutoff!(stopping_condition::EquityBehavioral, value::Int) = setfield!(stopping_condition, :period_cutoff, value)

"""
    period_count(stopping_condition::EquityBehavioral)

Get the current number of periods that the behavioral equity state has persisted.
"""
period_count(stopping_condition::EquityBehavioral) = getfield(stopping_condition, :period_count)

"""
    period_count!(stopping_condition::EquityBehavioral)

Set the number of periods that the behavioral equity state has persisted.
"""
period_count!(stopping_condition::EquityBehavioral, value::Int) = setfield!(stopping_condition, :period_count, value)

"""
    increment_period_count(stopping_condition::EquityBehavioral)

Increment the number of periods that the behavioral equity state has persisted.
"""
increment_period_count!(stopping_condition::EquityBehavioral, value::Int=1) = period_count!(stopping_condition, period_count(stopping_condition) + value)

"""
    period_cutoff(stopping_condition::PeriodCutoff)

Get the number of periods required to pass for the simulation to stop.
"""
period_cutoff(stopping_condition::PeriodCutoff) = getfield(stopping_condition, :period_cutoff)

"""
    displayname(stopping_condition::StoppingCondition)

Get the string used for displaying a StoppingCondition instance.
"""
displayname(stopping_condition::StoppingCondition) = type(stopping_condition)

Base.show(stopping_condition::StoppingCondition) = println(displayname(stopping_condition)) #make this more specific than name?