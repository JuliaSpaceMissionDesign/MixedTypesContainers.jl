@testset "Types" verbose=true begin

    @testset "ContainerDef construction" begin
        num = Array{Int, 0}(undef)
        num[] = 0

        cdef = MixedTypesContainers.ContainerDef("Name", MixedTypesContainers.DefaultContainerParameters())
        cdef2 = MixedTypesContainers.ContainerDef{MixedTypesContainers.DefaultContainerParameters}("Name")
        @test typeof(cdef) == typeof(cdef2)
        @test cdef.name == cdef2.name 
    end

    @testset "haschildrens" begin
        cdef = MixedTypesContainers.ContainerDef("Name", MixedTypesContainers.DefaultContainerParameters())
        cdef2 = MixedTypesContainers.ContainerDef("Name2", MixedTypesContainers.DefaultContainerParameters())
        @test !MixedTypesContainers.haschildrens(cdef)

        @test_throws Exception MixedTypesContainers.getchildcontainer(cdef, 1)
        @test_throws Exception MixedTypesContainers.getchildcontainer(cdef, :Name)

        push!(cdef.childrens, cdef2)
        @test MixedTypesContainers.getchildcontainer(cdef, 1) == cdef2
        @test MixedTypesContainers.getchildcontainer(cdef, :Name2) == cdef2
        @test_throws KeyError MixedTypesContainers.getchildcontainer(cdef, :Name) 
    end

    @testset "getters" begin
        cdef = MixedTypesContainers.parse_container(:(@container "Name" ("a" → A(), "b" → B(1.0), "c" → C())).args[3:end])
    
        @test MixedTypesContainers.getfields(cdef) == (:a, :b, :c)
        @test MixedTypesContainers.gettypes(cdef) == (:A, :B, :C)
        @test MixedTypesContainers.getinstances(cdef) == (:(A()), :(B(1.0)), :(C()))
    end

end

