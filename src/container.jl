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
