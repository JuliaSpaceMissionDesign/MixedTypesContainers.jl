export @container

# Create the new container structure
function defcontainer(exprargs)
    cdef = ContainerDef(exprargs[1])

    # parameters
    for arg in exprargs[2:(end - 1)]
        parse_container_parameters!(cdef, arg)
    end

    # arguments
    parse_container_args!(cdef, exprargs[end].args, Val(exprargs[end].head))

    return cdef
end

"""
    @container

A macro to create a new container
"""
macro container(expr...)
    # preprocess expression
    exprargs = Base.remove_linenums!.(expr)

    # define the container
    cdef = defcontainer(exprargs)

    tname = cdef.name

    return esc(
        quote
            # ---
            # Type definition
            struct $tname <: $(cdef.par.parenttype)
                data::NamedTuple{$(cdef.fnames),$(cdef.ftypes)}
            end

            # ---
            # Constructors
            $tname(data::Tuple) = $tname(NamedTuple{$(cdef.fnames)}(data))
            $tname(data::AbstractVector) = $tname(tuple(data...))

            # ---
            # Julia API
            Base.getindex(c::$tname, elements...) = Base.getindex(c.data, elements...)
            function Base.show(io::IO, c::$tname)
                println(io, "$($(tname))(items=$(length(c.data)))")
                return nothing
            end
        end,
    )
end
