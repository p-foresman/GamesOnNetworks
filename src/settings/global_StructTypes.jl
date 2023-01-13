#This file contains all global StructType assignments required for JSON3 functionality

#If a new payoff matrix size is used in a game (e.g. new Game{S1, S2}() is initialized), a new StructType must be added to this list 

using StructTypes


################################## Agent Type #######################################
StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable()



################################ SimParams Type #####################################
StructTypes.StructType(::Type{SimParams}) = StructTypes.Mutable()


############################## GraphParams Types ####################################
#This StructTypes hierarchy is required to reproduce any given subtype from the abstract type input
StructTypes.StructType(::Type{GraphParams}) = StructTypes.AbstractType()
StructTypes.StructType(::Type{CompleteParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{ErdosRenyiParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{SmallWorldParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{ScaleFreeParams}) = StructTypes.Struct()
StructTypes.StructType(::Type{StochasticBlockModelParams}) = StructTypes.Struct()
StructTypes.subtypekey(::Type{GraphParams}) = :graph_type
StructTypes.subtypes(::Type{GraphParams}) = (complete=CompleteParams, er=ErdosRenyiParams, sw=SmallWorldParams, sf=ScaleFreeParams, sbm=StochasticBlockModelParams)

####################### Xoshiro random number generator type ########################
#Needed to read and write the state of the Xoshiro RNG with JSON3 package
StructTypes.StructType(::Type{Random.Xoshiro}) = StructTypes.Mutable()



################################## Game Type ########################################
#Enter any new payoff matrix sizes here in the format: StructTypes.StructType(::Type{Game{rows, cols, length}}) = StructTypes.Struct()
StructTypes.StructType(::Type{Game{3, 3, 9}}) = StructTypes.Struct()