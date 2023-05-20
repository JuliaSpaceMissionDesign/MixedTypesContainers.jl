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

