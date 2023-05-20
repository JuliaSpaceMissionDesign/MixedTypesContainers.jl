# using Logging
# using Parameters
# using MacroTools

# abstract type AbstractContainer{N} end

# abstract type AbstractContainerParameters end

# @with_kw mutable struct DefaultContainerParameters <: AbstractContainerParameters
#     init::Bool = false
#     parenttype::Symbol = Symbol("AbstractContainer{N}")
# end

# struct ContainerDef{T<:AbstractContainerParameters}
#     name::Symbol
#     par::T

#     # typedef parameters
#     fnames::Vector{String}
#     ftypes::Vector{Symbol}
#     finsta::Vector{Expr}
#     fnum::Array{Int,0}
# end

# function ContainerDef(name::String, cpar::T) where {T<:AbstractContainerParameters}
#     num = Array{Int,0}(undef)
#     num[] = 0
#     return ContainerDef{T}(Symbol(name), cpar, [], [], [], num)
# end

# const CONTAINER_DEFAULT_FNAME = "FIELD"

# function define_container(exprargs, cpar::T=DefaultContainerParameters()) where T

#     # create the empty container struct
#     # this is the base structure to be filled during the object construction
#     cdef = ContainerDef(exprargs[1], cpar)

#     # parameters 
#     # TODO: get parameters
#     @info "Parsing contfunctionainer parameters"
    
#     # arguments 
#     @info "Parsing container arguments"
#     parse_args!(cdef, exprargs[end].args,  Val(exprargs[end].head))

#     return cdef

# end

# function parse_args!(cdef::ContainerDef, exprargs, ::Val{:tuple})
#     for argi in exprargs
#         @info "Arg: $argi"

#         if argi isa Expr 
#             parse_tuple_args!(cdef, argi, Val(argi.head))

#         elseif argi isa Symbol
#             # TODO: parse_symbol_args!(argi)

#         else
#             throw(
#                 error(
#                     "argument with type $(typeof(argi)) not allowed"
#                 )
#             )
#         end
#     end
#     nothing
# end

# function parse_args!(exprargs, ::Val{:vect})
#     return parse_args!(exprargs, Val{:tuple}())
# end

# function parse_args!(cdef::ContainerDef, args, ::Val{:block})
#     for arg in args
#         if !(arg isa LineNumberNode)
#             parse_tuple_args!(cdef, arg.args, Val(arg.head))
#         end
#     end
#     return nothing
# end

# function parse_tuple_args!(cdef::ContainerDef, argi, ::Val{:call})

#     arginst = nothing
#     argargs = argi.args
#     if argargs[1] == :(=>)
#         # "argname" => T(arginit...) or "argname" => T

#         if argargs[3] isa Expr 
#             # "argname" => T(arginit...)
#             T = argargs[3].args[1]
#             arginst = argargs[3] 

#         elseif argargs[3] isa Symbol
#             # "argname" => T
#             if length(cdef.finsta) > 0
#                 throw(error("all container fields shall be initialized"))
#             end
#             T = argargs[3]

#         else 
#             error()

#         end
#         argname = argargs[2]

#     elseif argargs[1] isa Symbol
#         # T(arginit...)
#         T = argargs[1]
#         arginst = cdef.finsta, argi
#         argname = "$(CONTAINER_DEFAULT_FNAME)$(cdef.fnum[]+1)"
    
#     else
#         error()
#     end

#     # push in the ContainerDef struct
#     push!(cdef.ftypes, T)
#     argname in cdef.fnames && throw(
#         KeyError(
#             "A field called '$argname' is already " *
#             "present in the container! Fields must be unique.",
#         ),
#     )
#     push!(cdef.fnames, argname)
#     !isnothing(arginst) && push!(cdef.finsta, arginst)
#     cdef.fnum[] += 1

#     if length(cdef.finsta) != length(cdef.fnames) && length(cdef.finsta) > 0
#         throw(error(
#             "all or none of the container fields shall be initialized"
#         ))
#     end    
#     nothing
    
# end

# function parse_tuple_args(arg)
# end

# function parse_block_args!(cdef::ContainerDef, argsi, ::Val{:macrocall})
#     # TODO: implement macro call within the container def
#     throw(error("macrocall parser not implemented"))
# end

# function parse_args(_, vt)
#     print(vt)
# end

# function parse_field!(cdef, argi)

#     arginst = nothing
#     argargs = argi.args
#     if argargs[1] == :(=>)
#         # "argname" => T(arginit...) or "argname" => T

#         if argargs[3] isa Expr 
#             # "argname" => T(arginit...)
#             T = argargs[3].args[1]
#             arginst = argargs[3] 

#         elseif argargs[3] isa Symbol
#             # "argname" => T
#             if length(cdef.finsta) > 0
#                 throw(error("all container fields shall be initialized"))
#             end
#             T = argargs[3]

#         else 
#             error()

#         end
#         argname = argargs[2]

#     elseif argargs[1] isa Symbol
#         # T(arginit...)
#         T = argargs[1]
#         arginst = cdef.finsta, argi
#         argname = "$(CONTAINER_DEFAULT_FNAME)$(cdef.fnum[]+1)"
    
#     else
#         error()
#     end

#     # push in the ContainerDef struct
#     push!(cdef.ftypes, T)
#     argname in cdef.fnames && throw(
#         KeyError(
#             "A field called '$argname' is already " *
#             "present in the container! Fields must be unique.",
#         ),
#     )
#     push!(cdef.fnames, argname)
#     !isnothing(arginst) && push!(cdef.finsta, arginst)
#     cdef.fnum[] += 1

#     if length(cdef.finsta) != length(cdef.fnames) && length(cdef.finsta) > 0
#         throw(error(
#             "all or none of the container fields shall be initialized"
#         ))
#     end    
#     nothing

# end

# macro container(expr...)
#     cname = expr[1]

#     # args are everything except the container name
#     cdef = define_container(expr)

#     print(cdef)

#     nothing

# end

# struct B 
#     x::Int64
# end
# "c" => 
# @container "Name" begin 
#     "a" => B, 
#     "b" => B 
# end

expr = :(
    @container "Name" begin
        "a" => B(1, 2)
        "b" => B(2, 3, 4, 5)
        "c" => @container "Container" begin
            "a" => B(2)
        end
        A
        A(2, 3)
        @container "Container" begin end
    end
)

expr = :(
    @container "Name" begin 
       A(1) 
    end
)

cdef = ContainerDef("Test", DefaultContainerParameters())

include("types.jl")
include("parse.jl")
