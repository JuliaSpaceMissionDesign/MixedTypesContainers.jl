@testset "Types" verbose=true begin

    @testset "ContainerDef construction" begin
        num = Array{Int, 0}(undef)
        num[] = 0

        cdef = ContainerDef("Name", DefaultContainerParameters())
        cdef2 = ContainerDef{DefaultContainerParameters}("Name")
        @test typeof(cdef) == typeof(cdef2)
        @test cdef.name == cdef2.name 
    end

    @testset "haschildrens" begin
        cdef = ContainerDef("Name", DefaultContainerParameters())
        cdef2 = ContainerDef("Name2", DefaultContainerParameters())
        @test !haschildrens(cdef)

        @test_throws Exception getchildcontainer(cdef, 1)
        @test_throws Exception getchildcontainer(cdef, :Name)

        push!(cdef.childrens, cdef2)
        @test getchildcontainer(cdef, 1) == cdef2
        @test getchildcontainer(cdef, :Name2) == cdef2
        @test_throws KeyError getchildcontainer(cdef, :Name) 
    end

end