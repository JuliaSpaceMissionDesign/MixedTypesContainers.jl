@testset "check_field_name" begin
    cdef = ContainerDef("Name", DefaultContainerParameters())
    @test check_field_name(cdef, nothing) == "$(CONTAINER_DEFAULT_FNAME)1"
    @test check_field_name(cdef, "name") == "name"
    push!(cdef.fnames, "name")
    @test_throws KeyError check_field_name(cdef, "name")
end

@testset "check_field_instance" begin
    cdef = ContainerDef("Name", DefaultContainerParameters())
    @test !check_field_instance(cdef)
    
    push!(cdef.fnames, "name")
    @test !check_field_instance(cdef)

    push!(cdef.finsta, :(A(1)))
    @test check_field_instance(cdef)

    push!(cdef.fnames, "name2")
    @test_throws ArgumentError check_field_instance(cdef)

    push!(cdef.finsta, :(A(1)))
    @test check_field_instance(cdef)

    cdef = ContainerDef("Name", DefaultContainerParameters())
    push!(cdef.fnames, "f1")
    push!(cdef.fnames, "f2")
    push!(cdef.fnames, "f3")
    @test !check_field_instance(cdef)
    @test check_field_instance(cdef) == hasinstances(cdef)
end

@testset "check_recursion/getrecursive" begin

    @test_throws ArgumentError check_recursion(:(@dummy_macro ""))
    isrec, recexpr, name = getrecursive(:(@container "Name"))
    @test isrec
    @test isnothing(name)
    @test recexpr == :("Name")

end

@testset "parse_field!" begin

    field = :(A(1))
    cdef = ContainerDef("Test", DefaultContainerParameters())
    parse_field!(cdef, field)
    @test cdef.fnames[1] == "$(CONTAINER_DEFAULT_FNAME)1"
    @test cdef.finsta[1] == field
    @test cdef.ftypes[1] == :A 
    @test cdef.fnum[] == 1
    @test_throws ArgumentError parse_field!(cdef, :B)

    field = :(A(1, 2, 3, 4))
    cdef = ContainerDef("Test", DefaultContainerParameters())
    parse_field!(cdef, field)
    @test cdef.fnames[1] == "$(CONTAINER_DEFAULT_FNAME)1"
    @test cdef.finsta[1] == field
    @test cdef.ftypes[1] == :A 
    @test cdef.fnum[] == 1
    @test_throws ArgumentError parse_field!(cdef, :B)

    field = :B 
    cdef = ContainerDef("Test", DefaultContainerParameters())
    parse_field!(cdef, field)
    @test cdef.fnames[1] == "$(CONTAINER_DEFAULT_FNAME)1"
    @test length(cdef.finsta) == 0 
    @test cdef.ftypes[1] == :B
    @test cdef.fnum[] == 1
    @test_throws ArgumentError parse_field!(cdef, :(A(1)))

    field = :("name" → A)
    cdef = ContainerDef("Test", DefaultContainerParameters())
    parse_field!(cdef, field)
    @test cdef.fnames[1] == "name"
    @test length(cdef.finsta) == 0 
    @test cdef.ftypes[1] == :A 
    @test cdef.fnum[] == 1
    @test_throws KeyError parse_field!(cdef, :("name" → B))

    field = :("name" → A(1))
    cdef = ContainerDef("Test", DefaultContainerParameters())
    parse_field!(cdef, field)
    @test cdef.fnames[1] == "name"
    @test cdef.finsta[1] == :(A(1))
    @test cdef.ftypes[1] == :A 
    @test cdef.fnum[] == 1
    @test_throws ArgumentError parse_field!(cdef, :("error" → 1.0))
    @test_throws ArgumentError parse_field!(cdef, :("error" : B(1)))

end

@testset "parse_args!" verbose=true begin

    @testset "Val{:tuple}, Val{:vect}" begin 
        cdef = ContainerDef("Test", DefaultContainerParameters())
        parse_args!(cdef, [:A, :B], Val(:tuple))
        parse_args!(cdef, [:C, :D], Val(:vect))
        for (i, t) in enumerate([:A, :B, :C, :D])
            @test cdef.fnames[i] == "$(CONTAINER_DEFAULT_FNAME)$i"
            @test cdef.ftypes[i] == t
        end
        @test length(cdef.finsta) == 0
        @test cdef.fnum[] == 4
        
        cdef = ContainerDef("Test", DefaultContainerParameters())
        @test_throws ArgumentError parse_args!(cdef, [1.0, 2.0], Val(:tuple))
    end

    @testset "Val{:block}" begin
        expr = :(
            @container "Name" begin
                A 
                B 
                C
            end
        )
        cdef = ContainerDef("Test", DefaultContainerParameters())
        parse_args!(cdef, expr.args[end].args, Val(:block))
        @test length(cdef.finsta) == 0
        num = cdef.fnum[]
        @test num == 3
        @test cdef.fnames == ["$(CONTAINER_DEFAULT_FNAME)$(i)" for i in 1:num]
    end

    @testset "Method errors/unhandled cases" begin 
        cdef = ContainerDef("Test", DefaultContainerParameters())
        @test_throws ArgumentError parse_args!(cdef, 1.0, Val{:tuple}())
        @test_throws MethodError parse_args!(cdef, missing, Val{:vect}())
        @test_throws MethodError parse_args!(cdef, missing, Val{:call}())
        @test_throws MethodError parse_args!(cdef, missing, Val{:macrocall}())
    end

end

expr = :(
    @container "Name" begin
        A 
        B 
        C
    end
)
cdef = ContainerDef("Test", DefaultContainerParameters())
parse_args!(cdef, expr.args[end].args, Val(:block))