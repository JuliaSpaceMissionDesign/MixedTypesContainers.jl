module MixedTypesContainers

using Parameters
using MacroTools

export AbstractMixedTypesContainer, AbstractContainerParameters, @container

include("types.jl")
include("parse.jl")
include("container.jl")
include("iteration.jl")

end