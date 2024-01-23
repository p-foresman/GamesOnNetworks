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