const CONTAINER_DEFAULT_FNAME = "FIELD"
const CONTAINER_TOKEN = :(→)

"""
    check_field_name(cdef, argname)

Check if `argname` is a feasable field name for `cdef` or construct a proper name in case 
`argname` is `nothing`.
"""
function check_field_name(cdef::ContainerDef, argname)
    argname = isnothing(argname) ? "$(CONTAINER_DEFAULT_FNAME)$(cdef.fnum[]+1)" : argname
    argname in cdef.fnames && throw(
        KeyError(
            "A field called '$argname' is already " *
            "present in the container! Fields must be unique.",
        ),
    )
    return argname 
end

"""
    check_field_instance(cdef)

Check if `cdef` fields can be properly instanciated.
"""
function check_field_instance(cdef::ContainerDef)
    ninsta = length(cdef.finsta)
    if ninsta != length(cdef.fnames) && ninsta > 0 
        throw(
            ArgumentError("all or none of the $(cdef.name) container fields shall be initialized")
        )
    elseif ninsta == 0
        return false 
    else
        return true 
    end
end

function hasinstances(cdef::ContainerDef)
    return check_field_instance(cdef)
end


# check if there are subcontainers
function check_recursion(expr)

    if expr isa Expr
        isamacro = expr.head == :macrocall 

        if isamacro
            macroname = expr.args[1]
            isacontainer = macroname == Symbol("@container")
            if isacontainer 
                return true, expr.args[3:end]
            else 
                throw(ArgumentError("$macroname macro not currenty handled"))
            end
        end
    end

    return false, Any[]

end

function getrecursive(expr)

    # "name" → @container 
    if expr.args[1] == CONTAINER_TOKEN
        isrecurrent, subexpr = check_recursion(expr.args[end])
        if isrecurrent
            return true, subexpr, expr.args[2]
        end
    end

    # @container ... 
    isrecurrent, subexpr = check_recursion(expr)
    if isrecurrent
        return true, subexpr, nothing
    end
    return false, Any[], nothing
   
end

# ---------------------------
# FIELDS
# ---------------------------

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

        elseif argargs[1] isa Symbol && !(argargs[1] in (:(:), :(=), :(=>), :(>), :(<), :(~)))
            # T(arginit...)
            T = argargs[1]
            arginst = arg
            
        else
            throw(ArgumentError("$arg container field cannot be processed"))

        end
    end
    
    # name
    argname = check_field_name(cdef, argname)
    push!(cdef.fnames, argname)

    # type
    push!(cdef.ftypes, T)

    # instance
    !isnothing(arginst) && push!(cdef.finsta, arginst)
    check_field_instance(cdef)

    # item number
    cdef.fnum[] += 1
    push!(cdef.ischild, false)
    nothing

end

function parse_recursive_field!(cdef::ContainerDef{T}, recargs, recname) where {T}
    scdef = parse_container(recargs, T())

    # name
    argname = check_field_name(cdef, recname)
    push!(cdef.fnames, argname)

    # type
    push!(cdef.ftypes, scdef.name)

    # instance 
    if hasinstances(scdef)
        push!(cdef.finsta, :($(scdef.name)()))
    end
    check_field_instance(cdef)

    # childrens
    push!(cdef.childrens, scdef)

    # item 
    cdef.fnum[] += 1
    push!(cdef.ischild, true)

    nothing
end

# ---------------------------
# ARGS
# ---------------------------

function parse_args!(cdef::ContainerDef, exprargs, ::Val{:tuple})
    for argi in exprargs
        if argi isa Expr || argi isa Symbol
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
            isrec, recargs, recname = getrecursive(argi)
            if isrec 
                parse_recursive_field!(cdef, recargs, recname)
            else
                parse_field!(cdef, argi)
            end

        elseif argi isa Symbol
            parse_field!(cdef, argi)

        elseif argi isa LineNumberNode
            # pass - LineNumberNode case

        else
            throw(ErrorException("you shouldn't arrive here")) 

        end
    end
    nothing
end

# macro container(expr...)

#     # TODO: non DefaultContainerParameters case 
    
#     # DefaultContainerParameters
#     cpar = DefaultContainerParameters()

#     cdef = parse_container(expr, cpar)
#     print(cdef) 

#     return nothing
# end
