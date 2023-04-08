
# ----
# Parameters

function parse_container_parameters!(cdef::ContainerDef, expr::Expr)
    return parse_container_parameters!(cdef, expr.args, Val(expr.head))
end

function parse_container_parameters!(cdef, args, head)
    return nothing
end
function parse_container_parameters!(cdef::ContainerDef, args, ::Val{:(=)})
    setfield!(cdef.par, args[1], args[2])
    return nothing
end

# ----
# Args

function parse_container_args!(cdef, args, head)
    return nothing
end

function parse_container_args!(cdef, args, ::Val{:block})
    for arg in args
        parse_container_fields!(cdef, arg.args, Val(arg.head))
    end
    return nothing
end

# ----
# Fields

function _parse_field!(cdef, f)
    fname = nothing

    arg = f.args
    if arg[1] == :(→)
        # name of the field assigned by the user
        if arg[3] isa Symbol
            # "name" → T
            cdef.par.init &&
                throw(error("Cannot initialize container defined on types only!"))
            push!(cdef.ftypes, arg[3])

        else
            # "name" → T(args..)
            push!(cdef.ftypes, arg[3].args[1])
            cdef.par.init && push!(cdef.finsta, arg[3])
        end
        # user defined name
        fname = arg[2]

    else
        # name of the field assigned by default
        push!(cdef.ftypes, arg[1])
        cdef.par.init && push!(cdef.finsta, f)
    end

    return fname
end

function parse_container_fields!(cdef, fargs, ::Val{:macrocall})
    # TODO: implement the recursive field parse
    return nothing
end

function parse_container_fields!(cdef, f, ::Val{:call})
    # Single element in the container

    fname_ = _parse_field!(cdef, Expr(:call, f...))

    fname = if !isnothing(fname_)
        fname_
    else
        "$(CONTAINER_DEFAULT_FNAME)$(cdef.fnum[]+1)"
    end

    cdef.fnum[] += 1
    fname in cdef.fnames && throw(
        error(
            "A field called '$fname' is already " *
            " present in the container! Fields must be unique.",
        ),
    )
    push!(cdef.fnames, fname)

    return nothing
end

function parse_container_fields!(cdef, fargs, ::Val{:tuple})
    for f in fargs
        fname = "$(CONTAINER_DEFAULT_FNAME)$(cdef.fnum[]+1)"

        if f isa Symbol
            # In this case within the container definition there are only types
            cdef.par.init &&
                throw(error("Cannot initialize container defined on types only!"))
            push!(cdef.ftypes, f)

        elseif f.head == :call
            fname_ = _parse_field!(cdef, f)
            if !isnothing(fname_)
                fname = fname_
            end

        else
            throw(error("Error in parsing container fields!"))
        end
        cdef.fnum[] += 1

        fname in cdef.fnames && throw(
            error(
                "A field called '$fname' is already " *
                " present in the container! Fields must be unique.",
            ),
        )
        push!(cdef.fnames, fname)
    end
    return nothing
end
