module Generators
    export
        ErdosRenyiModelGenerator,
        SmallWorldModelGenerator,
        ScaleFreeModelGenerator,
        StochasticBlockModelGenerator,
        ModelGenerator,
        generate_model,
        get_model_id #NOTE: this one is specific for my stuff on OSG, maybe delete

    import ..Database

    using ..GamesOnNetworks

    include("graphmodel_generators.jl")
    include("model_generators.jl")
end #Generators