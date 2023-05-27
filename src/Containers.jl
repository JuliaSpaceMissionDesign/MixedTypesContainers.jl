module Containers

using Parameters
using MacroTools

export AbstractContainer, AbstractContainerParameters, @container

include("types.jl")
include("parse.jl")
include("container.jl")
include("iteration.jl")

end