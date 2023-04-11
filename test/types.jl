@testset "getfields" begin
    cdef = Containers.ContainerDef{Containers.DefaultContainerParameters}("Test")
    @test isempty(Containers.getfields(cdef))
    @test isempty(Containers.gettypes(cdef))
    @test isempty(Containers.getinstances(cdef))

    Containers.parse_container_fields!(cdef, [:A], Val(:call))
    @test :A in Containers.gettypes(cdef)
    @test :fld1 in Containers.getfields(cdef)
end
