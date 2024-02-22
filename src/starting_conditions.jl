abstract type StartingCondition end

struct FractiousState <: StartingCondition
    name::String
    # game::Game

    function FractiousState()
        return new("fractious")
    end
end

struct EquityState <: StartingCondition
    name::String
    # game::Game

    function EquityState()
        return new("equity")
    end
end

struct RandomState <: StartingCondition
    name::String
    # game::Game

    function RandomState()
        return new("random")
    end
end


"""
StartingCondition Accessors
"""
type(starting_condition::StartingCondition) = getfield(starting_condition, :name)

displayname(starting_condition::StartingCondition) = type(starting_condition)
Base.show(starting_condition::StartingCondition) = println(displayname(starting_condition))