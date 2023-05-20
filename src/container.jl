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
