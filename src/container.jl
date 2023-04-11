export @container

"""
    define_container(exprargs)

Create a new `ContainerDef` with the container definitions.
"""
function define_container(exprargs; T::DataType=DefaultContainerParameters)
    cdef = ContainerDef{T}(exprargs[1])

    # parameters
    for arg in exprargs[2:(end - 1)]
        parse_container_parameters!(cdef, arg)
    end

    # arguments
    parse_container_args!(cdef, exprargs[end].args, Val(exprargs[end].head))

    return cdef
end

"""
    define_container(cdef)

Create a new container and the associated methods.
"""
function create_container(cdef)
    name = cdef.name

    fields = getfields(cdef)
    types = gettypes(cdef)

    if length(unique(types)) == 1
        nfields = length(fields)
        nttype = :(NTuple{$nfields,$(types[1])})
    else
        nttype = :(Tuple{$(types...)})
    end

    return quote
        # ---
        # Type definition
        struct $name <: $(cdef.par.parenttype)
            data::NamedTuple{$fields,$nttype}
        end

        # ---
        # Constructors
        $name(data::$nttype) = $name(NamedTuple{$fields}(data))
        $name(data::AbstractVector) = $name(tuple(data...))

        # ---
        # Julia API
        Base.getindex(c::$name, elements...) = Base.getindex(c.data, elements...)
        function Base.show(io::IO, c::$name)
            println(io, "$($name)(items=$(length(c.data)))")
            return nothing
        end
    end
end

function create_cinstance(cdef)
    instances = getinstances(cdef)
    instance = :(tuple($(instances...)))
    if length(instances) == cdef.fnum[]
        # Create a default empty constructor
        name = cdef.name
        return quote
            function $name()
                return $name($instance)
            end
            $name()
        end
    else
        return :(nothing)
    end
end

"""
    @container

Create a new container.
"""
macro container(exprargs...)
    # preprocess expression to remove line numbers
    exprargs = Base.remove_linenums!.(exprargs)

    # define the container fields
    cdef = define_container(exprargs)

    # create the container str and methods
    cstr = create_container(cdef)
    cins = create_cinstance(cdef)

    return esc(
        quote
            $cstr
            $cins
        end
    )
end
