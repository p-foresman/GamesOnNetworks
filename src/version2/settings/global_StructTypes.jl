#This file contains all global StructType assignments required for JSON3 functionality

#If a new payoff matrix size is used in a game (e.g. new Game{S1, S2}() is initialized), a new StructType must be added to this list 

using StructTypes


################################## Agent Type #######################################
StructTypes.StructType(::Type{Agent}) = StructTypes.Mutable()



################################ SimParams Type #####################################
StructTypes.StructType(::Type{SimParams}) = StructTypes.Mutable()



####################### Xoshiro random number generator type ########################
#Needed to read and write the state of the Xoshiro RNG with JSON3 package
StructTypes.StructType(::Type{Random.Xoshiro}) = StructTypes.Mutable()



################################## Game Type ########################################
#Enter any new payoff matrix sizes here in the format: StructTypes.StructType(::Type{Game{rows, cols}}) = StructTypes.Struct()
StructTypes.StructType(::Type{Game{3, 3}}) = StructTypes.Struct()