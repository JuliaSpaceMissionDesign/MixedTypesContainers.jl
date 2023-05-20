using Parameters

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
    subcont::Vector{ContainerDef{T}}
end

function ContainerDef{T}(name) where {T<:AbstractContainerParameters}
    num = Array{Int,0}(undef)
    num[] = 0
    return ContainerDef{T}(Symbol(name), T(), [], [], [], num, []) 
end

function ContainerDef(name, cpar::T) where {T<:AbstractContainerParameters}
    num = Array{Int,0}(undef)
    num[] = 0
    return ContainerDef{T}(Symbol(name), cpar, [], [], [], num, [])
end

@inline haschildcontainer(cdef::ContainerDef) = length(cdef.subcont) > 0

@inline function getchildcontainer(cdef::ContainerDef, i::Int) 
    if haschildcontainer(cdef) 
        return cdef.subcont[i]
    else 
        throw(ErrorException("$(cdef.name) has no child containers"))
    end
end

@inline function getchildcontainer(cdef::ContainerDef, name::Symbol)
    if haschildcontainer(cdef)
        for ci in cdef.subcont
            if ci.name == name 
                return ci 
            end
        end
        throw(KeyError("$(cdef.name) does not have any child container called $name"))
    else
        throw(ErrorException("$(cdef.name) has no child containers"))
    end
end


using Test

@testset "Types" verbose=true begin

    @testset "ContainerDef construction" begin
        num = Array{Int, 0}(undef)
        num[] = 0

        cdef = ContainerDef("Name", DefaultContainerParameters())
        cdef2 = ContainerDef{DefaultContainerParameters}("Name")
        @test typeof(cdef) == typeof(cdef2)
        @test cdef.name == cdef2.name 
    end

    @testset "haschildcontainer" begin
        cdef = ContainerDef("Name", DefaultContainerParameters())
        cdef2 = ContainerDef("Name2", DefaultContainerParameters())
        @test !haschildcontainer(cdef)

        push!(cdef.subcont, cdef2)
        @test getchildcontainer(cdef, 1) == cdef2
        @test getchildcontainer(cdef, :Name2) == cdef2
    end

end