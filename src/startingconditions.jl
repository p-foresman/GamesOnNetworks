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
    name::String
    # game::Game

    function FractiousState()
        return new("fractious")
    end
end

"""
    EquityState

Type denoting the "equity state" starting condition.
"""
struct EquityState <: StartingCondition
    name::String
    # game::Game

    function EquityState()
        return new("equity")
    end
end

"""
    RandomState

Type denoting the "random state" starting condition.
"""
struct RandomState <: StartingCondition
    name::String
    # game::Game

    function RandomState()
        return new("random")
    end
end


##########################################
# StartingCondition Accessors
##########################################

"""
    type(starting_condition::StartingCondition)

Get the starting condition type.
"""
type(starting_condition::StartingCondition) = getfield(starting_condition, :name)

"""
    displayname(starting_condition::StartingCondition)

Get the string used for displaying a StartingCondition instance.
"""
displayname(starting_condition::StartingCondition) = type(starting_condition)

Base.show(starting_condition::StartingCondition) = println(displayname(starting_condition))