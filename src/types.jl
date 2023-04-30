export AbstractContainer

abstract type AbstractContainer{N} end

abstract type AbstractContainerParameters end

"""
    DefaultContainerParameters <: AbstractContainerParameters

A collection of Containers allowed parameters with their default values.

### Fields
- `init::Bool` -- Initialize the container. Default to `false`.
- `parenttype::DataType` -- Type of the container parent. Default to `AbstractContainer`.
"""
@with_kw mutable struct DefaultContainerParameters <: AbstractContainerParameters
    init::Bool = false
    parenttype::Symbol = Symbol("AbstractContainer{N}")
end

"""
    ContainerDef

A type to handle the required parameters to create a new container.

### Fields
- `name::Symbol` -- Name of the container
- `par::AbstractContainerParameters` -- Containter options

- `fnames::Vector{String}` -- Name of the container fields
- `ftypes::Vector{Symbol}` -- Types of the container fields
- `finsta::Vector{Expr}` -- Instances of the container fields, if required
- `fnum::Array{Int, 0}` -- Number of items in the container

### Constructor
- `ContainerDef(name::String)` -- default constructor by name
"""
struct ContainerDef{T<:AbstractContainerParameters}
    name::Symbol
    par::T

    # typedef parameters
    fnames::Vector{String}
    ftypes::Vector{Symbol}
    finsta::Vector{Expr}
    fnum::Array{Int,0}

    function ContainerDef{T}(name::String) where {T<:AbstractContainerParameters}
        num = Array{Int,0}(undef)
        num[] = 0
        return new(Symbol(name), T(), [], [], [], num)
    end
end

"""
    getfields(cdef::ContainerDef)

Get container fields names.
"""
function getfields(cdef::ContainerDef)
    return ntuple(i -> Symbol(cdef.fnames[i]), cdef.fnum[])
end

"""
    gettypes(cdef::ContainerDef)

Get container fields types.
"""
function gettypes(cdef::ContainerDef)
    return ntuple(i -> cdef.ftypes[i], cdef.fnum[])
end

"""
    getinstances(cdef::ContainerDef)

Get container fields instance definitions.
"""
function getinstances(cdef::ContainerDef)
    return ntuple(i -> cdef.finsta[i], cdef.fnum[])
end

function Base.show(io::IO, cdef::ContainerDef{T}) where {T<:AbstractContainerParameters}
    println(io, "ContainerDef{$T}(")
    println(io, " name = $(cdef.name)")
    println(io, " par = $(cdef.par)")
    println(io, " fnum = $(cdef.fnum[])")
    println(io, " fnames = $(cdef.fnames)")
    println(io, " ftypes = $(cdef.ftypes)")
    println(io, ")")
    return nothing
end
