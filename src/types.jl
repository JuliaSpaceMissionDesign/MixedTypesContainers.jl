abstract type AbstractContainer{N} end

abstract type AbstractContainerParameters end

@with_kw mutable struct DefaultContainerParameters <: AbstractContainerParameters
    init::Bool = false
    parenttype::Symbol = Symbol("AbstractContainer{N}")
end

struct ContainerDef{T<:AbstractContainerParameters}
    name::Symbol
    par::T

    # typedef parameters
    fnames::Vector{String}
    ftypes::Vector{Symbol}
    finsta::Vector{Expr}
    fnum::Array{Int,0}

    # subcotainers
    childrens::Vector{ContainerDef{T}}
    ischild::Vector{Bool}
end

function ContainerDef{T}(name) where {T<:AbstractContainerParameters}
    num = Array{Int,0}(undef)
    num[] = 0
    return ContainerDef{T}(Symbol(name), T(), String[], Symbol[], Expr[], num, [], Bool[]) 
end

function ContainerDef(name, cpar::T) where {T<:AbstractContainerParameters}
    num = Array{Int,0}(undef)
    num[] = 0
    return ContainerDef{T}(Symbol(name), cpar, String[], Symbol[], Expr[], num, [], Bool[])
end

"""
    haschildrens(cdef::ContainerDef)

Return `true` if the container that will be defined with `cdef` has child containers.
"""
@inline haschildrens(cdef::ContainerDef) = length(cdef.childrens) > 0

@inline function getchildcontainer(cdef::ContainerDef, i::Int) 
    if haschildrens(cdef) 
        return cdef.childrens[i]
    else 
        throw(ErrorException("$(cdef.name) has no child containers"))
    end
end

@inline function getchildcontainer(cdef::ContainerDef, name::Symbol)
    if haschildrens(cdef)
        for ci in cdef.childrens
            if ci.name == name 
                return ci 
            end
        end
        throw(KeyError("$(cdef.name) does not have any child container called $name"))
    else
        throw(ErrorException("$(cdef.name) has no child containers"))
    end
end

"""
    getfields(cdef::ContainerDef)

Get container fields names.
"""
@inline function getfields(cdef::ContainerDef)
    return ntuple(i -> Symbol(cdef.fnames[i]), cdef.fnum[])
end

"""
    gettypes(cdef::ContainerDef)

Get container fields types.
"""
@inline function gettypes(cdef::ContainerDef)
    return ntuple(i -> cdef.ftypes[i], cdef.fnum[])
end

"""
    getinstances(cdef::ContainerDef)

Get container fields instance definitions.
"""
@inline function getinstances(cdef::ContainerDef)
    return ntuple(i -> cdef.finsta[i], cdef.fnum[])
end

@inline function gettmap(c::C) where {C <: AbstractContainer}
    return c.typemap
end