module Containers

using Parameters
using MacroTools

const CONTAINER_DEFAULT_FNAME = "F"

include("types.jl")
include("parse.jl")
include("container.jl")
include("iterate.jl")

end
