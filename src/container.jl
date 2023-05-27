
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

function create_container(cdef::ContainerDef)
    name = cdef.name
    fields = getfields(cdef)
    types = gettypes(cdef)
    utypes = unique(types)
    ntypes = length(utypes)
    nfields = cdef.fnum[]
    parent = cdef.par.parenttype

    # NTuple arguments and signature
    if ntypes == 1 
        ntarg = :(NTuple{$nfields, $(types[1])})
    else
        ntarg = :(Tuple{$(types...)})
    end
    nttype = :(NamedTuple{$fields, $ntarg})

    # Child containers
    subcont = []
    if haschildrens(cdef)
        for scdef in cdef.childrens
            push!(subcont, create_container(scdef))
        end
    end

    # Type map
    tmap = Dict{Symbol, Vector{Int}}()
    for ut in utypes 
        push!(tmap, ut => findall(x -> x == ut, types))
    end

    # args constructors 
    argconstr_args = Expr[]
    for (f, t) in zip(fields, types)
        push!(argconstr_args, :($f::$t))
    end
    argconstr = quote
        $(name)($(argconstr_args...)) = $name(tuple($(fields...)))
    end

    # Empty/kwargs constructors
    if hasinstances(cdef)
        instances = getinstances(cdef)
        instance = :(tuple($(instances...)))
        econstr = quote
            function $(name)()
                return $name($instance)
            end
            $name()
        end

        # # kwconstr
        # kargconstr_args = []
        # for (f, t, i) in zip(fields, types, instances)
        #     push!(kargconstr_args, :($f::$t = $i))
        # end
        # kwconstr = quote
        #     $(name)(;$(kargconstr_args...)) = $name(tuple($(fields...)))
        # end

    else 
        econstr = :(nothing)
        kwconstr = :(nothing)

    end

    return quote
        # ---
        # Childrens containers
        $(subcont...)
        
        # ---
        # Type 
        struct $name{N, M} <: $(parent){N}
            data::$nttype
            typemap::Dict{Symbol, Vector{Int}}
            $(name)(data::$nttype) = new{$ntypes, $nfields}(data, $tmap)
        end

        # ---
        # Constructors
        $(name)(data::$ntarg) = $name(NamedTuple{$fields}(data))
        $(name)(data::AbstractVector) = $name(tuple(data...))
        $argconstr
        # $kwconstr

        # --- 
        # Utils
        @inline hasinstances(c::$name) = $(Containers.hasinstances(cdef))

        # --- 
        # Julia API 
        @inline function Base.getindex(c::$name, elements...) 
            return Base.getindex(c.data, elements...)
        end

        # Empty constructor (initialized container) 
        $econstr
    end
end


"""
    @container

Create a new container.
"""
macro container(expr...)

    pdef = DefaultContainerParameters()

    # define the container fields
    cdef = parse_container(expr, pdef)

    # create the container str and methods
    cstr = create_container(cdef)

    return esc(
        quote
            $cstr
        end,
    )
end