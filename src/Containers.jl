module Containers

using Parameters

export AbstractContainer, AbstractContainerParameters, DefaultContainerParameters,
       haschildrens, getchildcontainer, ContainerDef,

       # parse
       CONTAINER_DEFAULT_FNAME, CONTAINER_TOKEN,
       check_field_instance, check_field_name, check_recursion, hasinstances,
       getrecursive, parse_field!, parse_recursive_field!, parse_args!,

       # container
       parse_container

include("types.jl")
include("parse.jl")
include("container.jl")

end