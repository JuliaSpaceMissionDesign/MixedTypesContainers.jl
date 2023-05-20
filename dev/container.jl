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
    create_container(cdef)

Create a new container and the associated methods.
"""
function create_container(cdef)
    name = cdef.name

    fields = getfields(cdef)
    types = gettypes(cdef)
    ntyp = length(unique(types))
    nels = length(fields)

    if ntyp == 1
        nfields = length(fields)
        nttype = :(NTuple{$nfields,$(types[1])})
    else
        nttype = :(Tuple{$(types...)})
    end

    return quote
        # ---
        # Type definition
        struct $name{N,M} <: $(cdef.par.parenttype)
            data::NamedTuple{$fields,$nttype}
            $name(data::NamedTuple{$fields,$nttype}) = new{$ntyp,$nels}(data)
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

"""
    create_empty_constructor(cdef)

Create a new container empty constructor.
This can be created only if `init` parameter is set to `true`, otherwise
nothing is returned. The empty constructor, if available, is capable to 
initialize all the fields within the container.
"""
function create_empty_constructor(cdef)
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
    cins = create_empty_constructor(cdef)

    return esc(
        quote
            $cstr
            $cins
        end,
    )
end
