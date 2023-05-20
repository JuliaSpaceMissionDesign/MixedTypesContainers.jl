@testset "Types" verbose=true begin

    @testset "ContainerDef construction" begin
        num = Array{Int, 0}(undef)
        num[] = 0

        cdef = Containers.ContainerDef("Name", Containers.DefaultContainerParameters())
        cdef2 = Containers.ContainerDef{Containers.DefaultContainerParameters}("Name")
        @test typeof(cdef) == typeof(cdef2)
        @test cdef.name == cdef2.name 
    end

    @testset "haschildrens" begin
        cdef = Containers.ContainerDef("Name", Containers.DefaultContainerParameters())
        cdef2 = Containers.ContainerDef("Name2", Containers.DefaultContainerParameters())
        @test !Containers.haschildrens(cdef)

        @test_throws Exception Containers.getchildcontainer(cdef, 1)
        @test_throws Exception Containers.getchildcontainer(cdef, :Name)

        push!(cdef.childrens, cdef2)
        @test Containers.getchildcontainer(cdef, 1) == cdef2
        @test Containers.getchildcontainer(cdef, :Name2) == cdef2
        @test_throws KeyError Containers.getchildcontainer(cdef, :Name) 
    end

    @testset "getters" begin
        cdef = Containers.parse_container(:(@container "Name" ("a" → A(), "b" → B(1.0), "c" → C())).args[3:end])
    
        @test Containers.getfields(cdef) == (:a, :b, :c)
        @test Containers.gettypes(cdef) == (:A, :B, :C)
        @test Containers.getinstances(cdef) == (:(A()), :(B(1.0)), :(C()))
    end

end

