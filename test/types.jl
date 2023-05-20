@testset "Types" verbose=true begin

    @testset "ContainerDef construction" begin
        num = Array{Int, 0}(undef)
        num[] = 0

        cdef = ContainerDef("Name", DefaultContainerParameters())
        cdef2 = ContainerDef{DefaultContainerParameters}("Name")
        @test typeof(cdef) == typeof(cdef2)
        @test cdef.name == cdef2.name 
    end

    @testset "haschildcontainer" begin
        cdef = ContainerDef("Name", DefaultContainerParameters())
        cdef2 = ContainerDef("Name2", DefaultContainerParameters())
        @test !haschildrens(cdef)

        push!(cdef.childrens, cdef2)
        @test getchildcontainer(cdef, 1) == cdef2
        @test getchildcontainer(cdef, :Name2) == cdef2
    end

end