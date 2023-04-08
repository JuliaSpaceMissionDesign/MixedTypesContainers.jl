
@testset "_parse_field! function" begin

    cdef = Containers.ContainerDef("Test")

    Containers._parse_field!(cdef, Expr(:call, :A, 1))
    @test :A in cdef.ftypes

    fname = Containers._parse_field!(cdef, Expr(:call, :(→), "testb", :B))

    @test !("testb" in cdef.fnames)
    push!(cdef.fnames, fname)

    @test :B in cdef.ftypes
    @test "testb" in cdef.fnames

    fname = Containers._parse_field!(cdef, Expr(:call, :(→), "testc", :(C(1))))
    @test !("testc" in cdef.fnames)
    push!(cdef.fnames, fname)
    @test "testc" in cdef.fnames
end
