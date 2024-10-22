"""
    StartingCondition

An abstract type representing starting conditions for simulations.
"""
abstract type StartingCondition end

"""
    FractiousState

Type denoting the "fractious state" starting condition.
"""
struct FractiousState <: StartingCondition
    type::String
    function FractiousState()
        return new("FractiousState")
    end
    function FractiousState(::String)
        return new("FractiousState")
    end
    function FractiousState(::FractiousState) #used to get a "raw" version of the starting condition to send to the database
        return new("FractiousState")
    end
end

"""
    EquityState

Type denoting the "equity state" starting condition.
"""
struct EquityState <: StartingCondition
    type::String
    function EquityState()
        return new("EquityState")
    end
    function EquityState(::String)
        return new("EquityState")
    end
    function EquityState(::EquityState) #used to get a "raw" version of the starting condition to send to the database
        return EquityState("EquityState")
    end
end

"""
    RandomState

Type denoting the "random state" starting condition.
"""
struct RandomState <: StartingCondition
    type::String
    function RandomState()
        return new("RandomState")
    end
    function RandomState(::String)
        return new("RandomState")
    end
    function RandomState(::RandomState) #used to get a "raw" version of the starting condition to send to the database
        return RandomState("RandomState")
    end
end


##########################################
# StartingCondition Accessors
##########################################

"""
    type(startingcondition::StartingCondition)

Get the starting condition type.
"""
type(startingcondition::StartingCondition) = getfield(startingcondition, :type)
# type(::SC) where {SC<:StartingCondition} = string(SC)

"""
    displayname(startingcondition::StartingCondition)

Get the string used for displaying a StartingCondition instance.
"""
displayname(startingcondition::StartingCondition) = type(startingcondition)

Base.show(startingcondition::StartingCondition) = println(displayname(startingcondition))