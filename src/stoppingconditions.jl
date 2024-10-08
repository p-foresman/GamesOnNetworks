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
    strategy::Int
    sufficient_equity::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?) #NOTE: REMOVE
    sufficient_transitioned::Float64


    function EquityPsychological(strategy::Integer)
        return new("equity_psychological", strategy, 0., 0.)
    end
    function EquityPsychological(stoppingcondition::EquityPsychological) #used to get a "raw" version of the stopping condition to send to the database
        return EquityPsychological(strategy(stoppingcondition))
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
    strategy::Int
    sufficient_transitioned::Float64 #defined within constructor #could be eliminated (defined on a per-stopping condition basis) (do we want the stopping condition nested within SimParams?) #NOTE: REMOVE
    period_cutoff::Int #initialized to nothing (determine in simulation). DEFINITION: memory_length.
    period_count::Int #initialized at 0
    # func::Function #could hold the actual stopping condition function for easier user customization?
    

    function EquityBehavioral(strategy::Integer)
        return new("equity_behavioral", strategy, 0., 0, 0)
    end
    function EquityBehavioral(stoppingcondition::EquityBehavioral) #used to get a "raw" version of the stopping condition to send to the database
        return EquityBehavioral(strategy(stoppingcondition))
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
    function PeriodCutoff(stoppingcondition::PeriodCutoff) #used to get a "raw" version of the stopping condition to send to the database
        return PeriodCutoff(period_cutoff(stoppingcondition))
    end
end


##########################################
# StoppingCondition Accessors
##########################################

"""
    type(stoppingcondition::StoppingCondition)

Get the stopping condition type.
"""
type(stoppingcondition::StoppingCondition) = getfield(stoppingcondition, :name)

"""
    strategy(stoppingcondition::EquityPsychological)

Get the strategy that the stopping condition is targeted at.
"""
strategy(stoppingcondition::EquityPsychological) = getfield(stoppingcondition, :strategy)

"""
    sufficient_equity(stoppingcondition::EquityPsychological)

Get the value for the sufficient number of "strategy" instances in a given agent's memory.
"""
sufficient_equity(stoppingcondition::EquityPsychological) = getfield(stoppingcondition, :sufficient_equity)

"""
    sufficient_equity!(stoppingcondition::EquityPsychological)

Set the value for the sufficient number of "strategy" instances in a given agent's memory.
"""
sufficient_equity!(stoppingcondition::EquityPsychological, value::Float64) = setfield!(stoppingcondition, :sufficient_equity, value)

"""
    sufficient_transitioned(stoppingcondition::EquityPsychological)

Get the value for the sufficient number of agents that must be transitioned for the simulation to stop.
"""
sufficient_transitioned(stoppingcondition::EquityPsychological) = getfield(stoppingcondition, :sufficient_transitioned)

"""
    sufficient_transitioned!(stoppingcondition::EquityPsychological)

Set the value for the sufficient number of agents that must be transitioned for the simulation to stop.
"""
sufficient_transitioned!(stoppingcondition::EquityPsychological, value::Float64) = setfield!(stoppingcondition, :sufficient_transitioned, value)

"""
    strategy(stoppingcondition::EquityBehavioral)

Get the strategy that the stopping condition is targeted at.
"""
strategy(stoppingcondition::EquityBehavioral) = getfield(stoppingcondition, :strategy)

"""
    sufficient_transitioned(stoppingcondition::EquityBehavioral)

Get the value for the sufficient number of agents that must be transitioned for the period count to be incremented.
"""
sufficient_transitioned(stoppingcondition::EquityBehavioral) = getfield(stoppingcondition, :sufficient_transitioned)

"""
    sufficient_transitioned!(stoppingcondition::EquityBehavioral)

Set the value for the sufficient number of agents that must be transitioned for the period count to be incremented.
"""
sufficient_transitioned!(stoppingcondition::EquityBehavioral, value::Float64) = setfield!(stoppingcondition, :sufficient_transitioned, value)

"""
    period_cutoff(stoppingcondition::EquityBehavioral)

Get the number of periods required for the behavioral equity state to persist for the simulation to stop.
"""
period_cutoff(stoppingcondition::EquityBehavioral) = getfield(stoppingcondition, :period_cutoff)

"""
    period_cutoff!(stoppingcondition::EquityBehavioral)

Set the number of periods required for the behavioral equity state to persist for the simulation to stop.
"""
period_cutoff!(stoppingcondition::EquityBehavioral, value::Int) = setfield!(stoppingcondition, :period_cutoff, value)

"""
    period_count(stoppingcondition::EquityBehavioral)

Get the current number of periods that the behavioral equity state has persisted.
"""
period_count(stoppingcondition::EquityBehavioral) = getfield(stoppingcondition, :period_count)

"""
    period_count!(stoppingcondition::EquityBehavioral)

Set the number of periods that the behavioral equity state has persisted.
"""
period_count!(stoppingcondition::EquityBehavioral, value::Int) = setfield!(stoppingcondition, :period_count, value)

"""
    increment_period_count(stoppingcondition::EquityBehavioral)

Increment the number of periods that the behavioral equity state has persisted.
"""
increment_period_count!(stoppingcondition::EquityBehavioral, value::Int=1) = period_count!(stoppingcondition, period_count(stoppingcondition) + value)

"""
    period_cutoff(stoppingcondition::PeriodCutoff)

Get the number of periods required to pass for the simulation to stop.
"""
period_cutoff(stoppingcondition::PeriodCutoff) = getfield(stoppingcondition, :period_cutoff)

"""
    displayname(stoppingcondition::StoppingCondition)

Get the string used for displaying a StoppingCondition instance.
"""
displayname(stoppingcondition::StoppingCondition) = type(stoppingcondition)

Base.show(stoppingcondition::StoppingCondition) = println(displayname(stoppingcondition)) #make this more specific than name?