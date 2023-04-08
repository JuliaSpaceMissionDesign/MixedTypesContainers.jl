abstract type AbstractContainer end

"""
    ContainerParameters

A collection of Containers allowed parameters with their default values.

### Fields
- `init::Bool` -- Initialize the container. Default to `false`.
- `parenttype::DataType` -- Type of the container parent. Default to `AbstractContainer`.
"""
@with_kw mutable struct ContainerParameters
    init::Bool = false
    parenttype::DataType = AbstractContainer
end

"""
    ContainerDef

A type to handle the required parameters to create a new container.

### Fields
- `name::Symbol` -- Name of the container
- `par::ContainerParameters` -- Containter options

- `fnames::Vector{String}` -- Name of the container fields
- `ftypes::Vector{Symbol}` -- Types of the container fields
- `finsta::Vector{Expr}` -- Instances of the container fields, if required
- `fnum::Array{Int, 0}` -- Number of items in the container

### Constructor
- `ContainerDef(name::String)` -- default constructor by name
"""
struct ContainerDef
    name::Symbol
    par::ContainerParameters

    # typedef parameters
    fnames::Vector{String}
    ftypes::Vector{Symbol}
    finsta::Vector{Expr}
    fnum::Array{Int,0}

    function ContainerDef(name::String)
        num = Array{Int,0}(undef)
        num[] = 0
        return new(Symbol(name), ContainerParameters(), [], [], [], num)
    end
end

function Base.show(io::IO, cdef::ContainerDef)
    println(io, "ContainerDef(")
    println(io, " name = $(cdef.name)")
    println(io, " par = $(cdef.par)")
    println(io, " fnum = $(cdef.fnum[])")
    println(io, " fnames = $(cdef.fnames)")
    println(io, " ftypes = $(cdef.ftypes)")
    println(io, ")")
    return nothing
end
