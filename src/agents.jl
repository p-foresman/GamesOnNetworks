#constructor for individual agents with relevant fields (mutable to update object later)
const Percept = Int8
const PerceptSequence = Vector{Percept}
const TaggedPercept = Tuple{Symbol, Int8}
const TaggedPerceptSequence = Vector{TaggedPercept}
const Choice = Int8

# abstract type Agent end

mutable struct Agent #could make a TaggedAgent as well to separate tags
    name::String
    # tag::Union{Nothing, Symbol} #NOTE: REMOVE
    is_hermit::Bool
    wealth::Int #is this necessary? #NOTE: REMOVE
    memory::PerceptSequence
    rational_choice::Choice
    choice::Choice

    function Agent(name::String, wealth::Int, memory::PerceptSequence, rational_choice::Choice, choice::Choice) #initialize choice at 0 (representing no choice)
        return new(name, false, wealth, memory, rational_choice, choice)
    end
    function Agent(name::String, is_hermit::Bool)
        return new(name, is_hermit, 0, PerceptSequence([]), Choice(0), Choice(0))
    end
    function Agent(name::String)
        return new(name, false, 0, PerceptSequence([]), Choice(0), Choice(0))
    end
    function Agent()
        return new("", false, 0, PerceptSequence([]), Choice(0), Choice(0))
    end
end


"""
Agent Accessors
"""
ishermit(agent::Agent) = agent.is_hermit
memory(agent::Agent) = agent.memory
rational_choice(agent::Agent) = agent.rational_choice
choice(agent::Agent) = agent.choice


# mutable struct TaggedAgent #could make a TaggedAgent as well to separate tags
#     name::String
#     tag::Union{Nothing, Symbol} #NOTE: REMOVE
#     is_hermit::Bool
#     wealth::Int #is this necessary? #NOTE: REMOVE
#     memory::PerceptSequence
#     choice::Int8

#     function Agent(name::String, wealth::Int, memory::Vector{Tuple{Symbol, Int8}}, tag::Union{Nothing, Symbol} = nothing, choice::Int8 = Int8(0)) #initialize choice at 0 (representing no choice)
#         return new(name, tag, false, wealth, memory, choice)
#     end
#     function Agent(name::String, tag::Union{Nothing, Symbol} = nothing)
#         return new(name, tag, false, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
#     function Agent(name::String, is_hermit::Bool)
#         return new(name, nothing, is_hermit, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
#     function Agent(name::String)
#         return new(name, nothing, false, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
#     function Agent()
#         return new("", nothing, false, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
# end