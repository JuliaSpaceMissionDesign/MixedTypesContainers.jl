@testset "check_field_name" begin
    cdef = MixedTypesContainers.ContainerDef("Name", MixedTypesContainers.DefaultContainerParameters())
    @test MixedTypesContainers.check_field_name(cdef, nothing) == "$(MixedTypesContainers.CONTAINER_DEFAULT_FNAME)1"
    @test MixedTypesContainers.check_field_name(cdef, "name") == "name"
    push!(cdef.fnames, "name")
    @test_throws KeyError MixedTypesContainers.check_field_name(cdef, "name")
end

@testset "check_field_instance" begin
    cdef = MixedTypesContainers.ContainerDef("Name", MixedTypesContainers.DefaultContainerParameters())
    @test !MixedTypesContainers.check_field_instance(cdef)
    
    push!(cdef.fnames, "name")
    @test !MixedTypesContainers.check_field_instance(cdef)

    push!(cdef.finsta, :(A(1)))
    @test MixedTypesContainers.check_field_instance(cdef)

    push!(cdef.fnames, "name2")
    @test_throws ArgumentError MixedTypesContainers.check_field_instance(cdef)

    push!(cdef.finsta, :(A(1)))
    @test MixedTypesContainers.check_field_instance(cdef)

    cdef = MixedTypesContainers.ContainerDef("Name", MixedTypesContainers.DefaultContainerParameters())
    push!(cdef.fnames, "f1")
    push!(cdef.fnames, "f2")
    push!(cdef.fnames, "f3")
    @test !MixedTypesContainers.check_field_instance(cdef)
    @test MixedTypesContainers.check_field_instance(cdef) == MixedTypesContainers.hasinstances(cdef)
end

@testset "check_recursion/getrecursive" begin

    @test_throws ArgumentError MixedTypesContainers.check_recursion(:(@dummy_macro ""))
    isrec, recexpr, name = MixedTypesContainers.getrecursive(:(@container "Name"))
    @test isrec
    @test isnothing(name)
    @test recexpr == Any["Name"]

end

@testset "parse_field!" begin

    field = :(A(1))
    cdef = MixedTypesContainers.ContainerDef("Test", MixedTypesContainers.DefaultContainerParameters())
    MixedTypesContainers.parse_field!(cdef, field)
    @test cdef.fnames[1] == "$(MixedTypesContainers.CONTAINER_DEFAULT_FNAME)1"
    @test cdef.finsta[1] == field
    @test cdef.ftypes[1] == :A 
    @test cdef.fnum[] == 1
    @test_throws ArgumentError MixedTypesContainers.parse_field!(cdef, :B)

    field = :(A(1, 2, 3, 4))
    cdef = MixedTypesContainers.ContainerDef("Test", MixedTypesContainers.DefaultContainerParameters())
    MixedTypesContainers.parse_field!(cdef, field)
    @test cdef.fnames[1] == "$(MixedTypesContainers.CONTAINER_DEFAULT_FNAME)1"
    @test cdef.finsta[1] == field
    @test cdef.ftypes[1] == :A 
    @test cdef.fnum[] == 1
    @test_throws ArgumentError MixedTypesContainers.parse_field!(cdef, :B)

    field = :B 
    cdef = MixedTypesContainers.ContainerDef("Test", MixedTypesContainers.DefaultContainerParameters())
    MixedTypesContainers.parse_field!(cdef, field)
    @test cdef.fnames[1] == "$(MixedTypesContainers.CONTAINER_DEFAULT_FNAME)1"
    @test length(cdef.finsta) == 0 
    @test cdef.ftypes[1] == :B
    @test cdef.fnum[] == 1
    @test_throws ArgumentError MixedTypesContainers.parse_field!(cdef, :(A(1)))

    field = :("name" → A)
    cdef = MixedTypesContainers.ContainerDef("Test", MixedTypesContainers.DefaultContainerParameters())
    MixedTypesContainers.parse_field!(cdef, field)
    @test cdef.fnames[1] == "name"
    @test length(cdef.finsta) == 0 
    @test cdef.ftypes[1] == :A 
    @test cdef.fnum[] == 1
    @test_throws KeyError MixedTypesContainers.parse_field!(cdef, :("name" → B))

    field = :("name" → A(1))
    cdef = MixedTypesContainers.ContainerDef("Test", MixedTypesContainers.DefaultContainerParameters())
    MixedTypesContainers.parse_field!(cdef, field)
    @test cdef.fnames[1] == "name"
    @test cdef.finsta[1] == :(A(1))
    @test cdef.ftypes[1] == :A 
    @test cdef.fnum[] == 1
    @test_throws ArgumentError MixedTypesContainers.parse_field!(cdef, :("error" → 1.0))
    @test_throws ArgumentError MixedTypesContainers.parse_field!(cdef, :("error" : B(1)))

end

@testset "parse_args!" verbose=true begin

    @testset "Val{:tuple}, Val{:vect}" begin 
        cdef = MixedTypesContainers.ContainerDef("Test", MixedTypesContainers.DefaultContainerParameters())
        MixedTypesContainers.parse_args!(cdef, [:A, :B], Val(:tuple))
        MixedTypesContainers.parse_args!(cdef, [:C, :D], Val(:vect))
        for (i, t) in enumerate([:A, :B, :C, :D])
            @test cdef.fnames[i] == "$(MixedTypesContainers.CONTAINER_DEFAULT_FNAME)$i"
            @test cdef.ftypes[i] == t
        end
        @test length(cdef.finsta) == 0
        @test cdef.fnum[] == 4
        
        cdef = MixedTypesContainers.ContainerDef("Test", MixedTypesContainers.DefaultContainerParameters())
        @test_throws ArgumentError MixedTypesContainers.parse_args!(cdef, [1.0, 2.0], Val(:tuple))
    end

    @testset "Val{:block}" begin
        expr = :(
            @container "Name" begin
                A 
                B 
                C
            end
        )
        cdef = MixedTypesContainers.ContainerDef("Test", MixedTypesContainers.DefaultContainerParameters())
        MixedTypesContainers.parse_args!(cdef, expr.args[end].args, Val(:block))
        @test length(cdef.finsta) == 0
        num = cdef.fnum[]
        @test num == 3
        @test cdef.fnames == ["$(MixedTypesContainers.CONTAINER_DEFAULT_FNAME)$(i)" for i in 1:num]
    end

    @testset "Method errors/unhandled cases" begin 
        cdef = MixedTypesContainers.ContainerDef("Test", MixedTypesContainers.DefaultContainerParameters())
        @test_throws ArgumentError MixedTypesContainers.parse_args!(cdef, 1.0, Val{:tuple}())
        @test_throws MethodError MixedTypesContainers.parse_args!(cdef, missing, Val{:vect}())
        @test_throws MethodError MixedTypesContainers.parse_args!(cdef, missing, Val{:call}())
        @test_throws MethodError MixedTypesContainers.parse_args!(cdef, missing, Val{:macrocall}())
    end

end

@testset "parse_kwargs!" begin
    @test isnothing(MixedTypesContainers.parse_kwargs!(missing, missing, missing))
    cdef = MixedTypesContainers.ContainerDef("Test", MixedTypesContainers.DefaultContainerParameters())

    MixedTypesContainers.parse_kwargs!(cdef, [:init, true], Val(:(=)))
    @test cdef.par.init
    MixedTypesContainers.parse_kwargs!(cdef, :(init=false))
    @test !cdef.par.init
end