
function parse_container(exprargs, ::T=DefaultContainerParameters()) where T
    # create the empty container struct
    # this is the base structure to be filled during the object construction
    cdef = ContainerDef{T}(exprargs[1])   

    # parameters
    for arg in exprargs[2:(end - 1)]
        parse_kwargs!(cdef, arg)
    end

    # arguments/fields
    parse_args!(cdef, exprargs[end].args, Val(exprargs[end].head))

    return cdef
end

function create_empty_constructor(cdef::ContainerDef)
    instances = getinstances(cdef)
    instance = :(tuple($(instances...)))
    name = cdef.name

    return quote
        function $(name)()
            return $name($instance)
        end
    end
end

function create_container(cdef::ContainerDef)
    name = cdef.name
    fields = getfields(cdef)
    types = gettypes(cdef)
    utypes = unique(types)
    ntypes = length(utypes)
    nfields = cdef.fnum[]

    if ntypes == 1 
        ntarg = :(NTuple{$nfields, $(types[1])})
    else
        ntarg = :(Tuple{$(types...)})
    end
    nttype = :(NamedTuple{$fields, $ntarg})

    subcont = []
    if haschildrens(cdef)
        for scdef in cdef.childrens
            push!(subcont, create_container(scdef))
        end
    end

    # construct type map
    tmap = Dict{Symbol, Vector{Int}}()
    for ut in utypes 
        push!(tmap, ut => findall(x -> x == ut, types))
    end

    # empty constructor 
    econstr = if hasinstances(cdef)
        create_empty_constructor(cdef)
    else 
        :(nothing)
    end

    return quote
        # ---
        # Childrens containers
        $(subcont...)
        
        # ---
        # Type 
        struct $name{N, M} <: $(cdef.par.parenttype)
            data::$nttype
            typemap::Dict{Symbol, Vector{Int}}
            $(name)(data::$nttype) = new{$ntypes, $nfields}(data, $tmap)
        end

        # ---
        # Constructors
        $(name)(data::$ntarg) = $name(NamedTuple{$fields}(data))
        $(name)(data::AbstractVector) = $name(tuple(data...))

        # --- 
        # Utils
        @inline hasinstances(c::$name) = $(Containers.hasinstances(cdef))

        # --- 
        # Julia API 
        @inbounds function Base.getindex(c::$name, elements...) 
            return Base.getindex(c.data, elements...)
        end

        # Empty constructor (initialized container) 
        $econstr
    end
end
