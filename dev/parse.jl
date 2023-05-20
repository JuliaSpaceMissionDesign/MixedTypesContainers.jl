include("types.jl")

const CONTAINER_DEFAULT_FNAME = "FIELD"
const CONTAINER_TOKEN = :(→)

@testset "_check_field_name" begin
    cdef = ContainerDef("Name", DefaultContainerParameters())
    @test _check_field_name(cdef, nothing) == "$(CONTAINER_DEFAULT_FNAME)1"
    @test _check_field_name(cdef, "name") == "name"
    push!(cdef.fnames, "name")
    @test_throws KeyError _check_field_name(cdef, "name")
end

@testset "_check_field_init" begin
    cdef = ContainerDef("Name", DefaultContainerParameters())
    @test _check_field_init(cdef)
end

function _check_field_name(cdef, argname)
    argname = isnothing(argname) ? "$(CONTAINER_DEFAULT_FNAME)$(cdef.fnum[]+1)" : argname
    argname in cdef.fnames && throw(
        KeyError(
            "A field called '$argname' is already " *
            "present in the container! Fields must be unique.",
        ),
    )
    return argname 
end

function _check_field_init(cdef)
    if length(cdef.finsta) != length(cdef.fnames) && length(cdef.finsta) > 0
        throw(
            ArgumentError("all or none of the $(cdef.name) container fields shall be initialized")
        )
    end
    return true

end

cdef = ContainerDef("Name", DefaultContainerParameters())
_check_field_init(cdef)


function _check_field_init(cdef, arginst)
    _check_field_init(cdef)

    init = length(cdef.finsta) > 0 
    subinit = true
    hassub = false
    if length(cdef.subcont) > 0
        for cdefi in cdef.subcont
            subinit = subinit && _check_field_init(cdefi)
        end
        hassub = true
    else 
        subinit = false 
    end


    return init, subinit, has_sub_cont
    # if init && !subinit && hassub
    #     throw(ArgumentError("All subcontainers shall be initialized in initialized container"))

    # elseif subinit && !init 
    #     throw(ArgumentError("Main container not initialized but child ones are."))

    # elseif init && (subinit || !hassub) 
    #     return !isnothing(arginst)

    # else
    #     return false 

    # end

end

"""
    parse_field!(cdef::ContainerDef, arg)

Parse a new container field from `Expr` or `Symbol` argument `arg`.
"""
function parse_field!(cdef::ContainerDef, arg)

    arginst = nothing
    argname = nothing

    if arg isa Symbol
        # T
        T = arg

    else
        argargs = arg.args
        if argargs[1] == CONTAINER_TOKEN
            # "argname" → T(arginit...) or "argname" → T

            if argargs[3] isa Expr && argargs[3].head == :call
                # "argname" → T(arginit...)
                T = argargs[3].args[1]
                arginst = argargs[3] 

            elseif argargs[3] isa Symbol
                # "argname" → T
                if length(cdef.finsta) > 0
                    throw(ArgumentError("all or none of the container fields shall be initialized"))
                end
                T = argargs[3]

            else 
                throw(ArgumentError("$arg container field cannot be processed"))

            end
            argname = argargs[2]

        elseif argargs[1] isa Symbol && length(argargs) == 2
            # T(arginit...)
            T = argargs[1]
            arginst = arg
            
        else
            throw(ArgumentError("$arg container field cannot be processed"))

        end
    end
    

    # name
    argname = _check_field_name(cdef, argname)
    push!(cdef.fnames, argname)

    # type
    push!(cdef.ftypes, T)

    # instance
    ck = _check_field_init(cdef, arginst)
    @show ck
    ck && push!(cdef.finsta, arginst)

    # item number
    cdef.fnum[] += 1
    nothing

end

function parse_field!(cdef::ContainerDef, arg, ::Val{:call})
    return parse_field!(cdef, arg)
end

function parse_field!(cdef::ContainerDef{T}, arg, ::Val{:macrocall}) where T

    argname = nothing
    if arg.head == :macrocall 
        # macro(...)
        mname = arg.args[1]
        margs = arg.args[4:end]
        
    elseif arg.head == :call && length(arg.args) == 3 && arg.args[1] == CONTAINER_TOKEN
        # "name" → macro(...)

        argname = arg.args[2]
        mname = arg.args[end].args[1]
        margs = arg.args[end].args[3:end]

    else
        throw(error())
    end

    if mname != Symbol("@container") 
        throw(
            ArgumentError("Cannot parse elements which are constructed by the $mname macro. " * 
                "Only the @container macro is currently supported.")
            )
    end

    # create the sub-container
    scdef = parse_container(margs, T())

    # name
    argname = _check_field_name(cdef, argname)
    push!(cdef.fnames, argname)

    # type
    push!(cdef.ftypes, scdef.name)

    # instance
    # _check_field_init(cdef, arginst) && push!(cdef.finsta, arginst)
    # TODO: how to handle the sub-container instance? Can be ContainerName() - with a default empty constructor?

    # subcont 
    push!(cdef.subcont, scdef)

    # item number
    cdef.fnum[] += 1

end

function parse_args!(cdef::ContainerDef, exprargs, ::Val{:tuple})
    for argi in exprargs
        if argi isa Expr
            parse_field!(cdef, argi, Val(argi.head))
        elseif argi isa Symbol
            parse_field!(cdef, argi)
        else
            throw(ArgumentError("argument with type $(typeof(argi)) not allowed"))
        end
    end
    nothing
end

function parse_args!(cdef::ContainerDef, exprargs, ::Val{:vect})
    return parse_args!(cdef, exprargs, Val(:tuple))
end

function parse_args!(cdef::ContainerDef, exprargs, ::Val{:block})
    for argi in exprargs
        if argi isa Expr && !(argi isa LineNumberNode)
            # to handler recursive call, check if the argument is a Container
            argiargs = argi.args
            valarg = :call 
            if length(argiargs) == 3 && argiargs[1] == CONTAINER_TOKEN
                if !(argiargs[end] isa Symbol)
                    valarg = argiargs[end].head 
                end
            end 
            valarg = argi.head == :macrocall ? :macrocall : valarg

            parse_field!(cdef, argi, Val(valarg))

        elseif argi isa Symbol
            parse_field!(cdef, argi)
        else

        end
    end
end

function parse_container(exprargs, ::T=DefaultContainerParameters()) where T
    # create the empty container struct
    # this is the base structure to be filled during the object construction
    cdef = ContainerDef{T}(exprargs[1])   

    # paramenters 
    # TODO: parse container paramenters 

    # arguments/fields
    parse_args!(cdef, exprargs[end].args, Val(exprargs[end].head))

    return cdef
end

macro container(expr...)

    # TODO: non DefaultContainerParameters case 
    
    # DefaultContainerParameters
    cpar = DefaultContainerParameters()

    cdef = parse_container(expr, cpar)
    print(cdef) 

    return nothing
end

expr = :(
    @container "Name" begin
        "a" → A
        "b" → @container "SubName" begin
            "as" → A
        end
    end
)

p = DefaultContainerParameters()

cdef = parse_container(expr.args[3:end], p)

@macroexpand @container "Name" begin
    "a" → A(1)
    "b" → B(1)
end


1
# expr

# parse_args!(cdef, expr.args, Val(:block))

















# ---
# TESTS

using Test

@testset "parse_field!" begin

    field = :(A(1))
    cdef = ContainerDef("Test", DefaultContainerParameters())
    parse_field!(cdef, field)
    @test cdef.fnames[1] == "$(CONTAINER_DEFAULT_FNAME)1"
    @test cdef.finsta[1] == field
    @test cdef.ftypes[1] == :A 
    @test cdef.fnum[] == 1
    @test_throws ArgumentError parse_field!(cdef, :B)

    field = :B 
    cdef = ContainerDef("Test", DefaultContainerParameters())
    parse_field!(cdef, field)
    @test cdef.fnames[1] == "$(CONTAINER_DEFAULT_FNAME)1"
    @test length(cdef.finsta) == 0 
    @test cdef.ftypes[1] == :B
    @test cdef.fnum[] == 1
    @test_throws ArgumentError parse_field!(cdef, :(A(1)))

    field = :("name" → A)
    cdef = ContainerDef("Test", DefaultContainerParameters())
    parse_field!(cdef, field)
    @test cdef.fnames[1] == "name"
    @test length(cdef.finsta) == 0 
    @test cdef.ftypes[1] == :A 
    @test cdef.fnum[] == 1
    @test_throws KeyError parse_field!(cdef, :("name" → B))

    field = :("name" → A(1))
    cdef = ContainerDef("Test", DefaultContainerParameters())
    parse_field!(cdef, field)
    @test cdef.fnames[1] == "name"
    @test cdef.finsta[1] == :(A(1))
    @test cdef.ftypes[1] == :A 
    @test cdef.fnum[] == 1
    @test_throws ArgumentError parse_field!(cdef, :("error" → 1.0))
    @test_throws ArgumentError parse_field!(cdef, :("error" : B(1)))

end

@testset "parse_args!" verbose=true begin

    @testset "Val{:call}" begin 
        cdef = ContainerDef("Test", DefaultContainerParameters())
        parse_args!(cdef, [:A, :B], Val(:tuple))
        parse_args!(cdef, [:C, :D], Val(:vect))
        for (i, t) in enumerate([:A, :B, :C, :D])
            @test cdef.fnames[i] == "$(CONTAINER_DEFAULT_FNAME)$i"
            @test cdef.ftypes[i] == t
        end
        @test length(cdef.finsta) == 0
        @test cdef.fnum[] == 4
        
        cdef = ContainerDef("Test", DefaultContainerParameters())
        @test_throws ArgumentError parse_args!(cdef, [1.0, 2.0], Val(:tuple))
    end

    @testset "Method errors/unhandled cases" begin 
        cdef = ContainerDef("Test", DefaultContainerParameters())
        @test_throws ArgumentError parse_args!(cdef, 1.0, Val{:tuple}())
        @test_throws MethodError parse_args!(cdef, missing, Val{:vect}())
        @test_throws MethodError parse_args!(cdef, missing, Val{:call}())
        @test_throws MethodError parse_args!(cdef, missing, Val{:macrocall}())
    end

end