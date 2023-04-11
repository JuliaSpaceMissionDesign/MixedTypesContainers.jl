
# ---
# Fields

@testset "_parse_field!" begin
    cdef = Containers.ContainerDef{Containers.DefaultContainerParameters}("Test")

    Containers._parse_field!(cdef, Expr(:call, :A, 1))
    @test :A in cdef.ftypes

    fname = Containers._parse_field!(cdef, Expr(:call, :(→), "testb", :B))

    @test !("testb" in cdef.fnames)
    push!(cdef.fnames, fname)

    @test isempty(cdef.finsta)
    @test :B in cdef.ftypes
    @test "testb" in cdef.fnames

    fname = Containers._parse_field!(cdef, Expr(:call, :(→), "testc", :(C(1))))
    @test !("testc" in cdef.fnames)
    push!(cdef.fnames, fname)

    @test "testc" in cdef.fnames
    @test :C in cdef.ftypes
    @test isempty(cdef.finsta)

    cdef = Containers.ContainerDef{Containers.DefaultContainerParameters}("Test")
    cdef.par.init = true
    @test_throws Exception Containers._parse_field!(cdef, Expr(:call, :(→), "name", :A))
end

@testset "parse_container_fields__macrocall" begin
    cdef = Containers.ContainerDef{Containers.DefaultContainerParameters}("Test")
    Containers.parse_container_fields!(cdef, nothing, Val(:macrocall))

    @test isempty(cdef.fnames)
    @test isempty(cdef.ftypes)
    @test isempty(cdef.finsta)
end

@testset "parse_container_fields__call" begin
    cdef = Containers.ContainerDef{Containers.DefaultContainerParameters}("Test")

    Containers.parse_container_fields!(cdef, [:A], Val(:call))
    @test :A in cdef.ftypes
    @test "fld1" in cdef.fnames

    Containers.parse_container_fields!(cdef, [:A, 1], Val(:call))
    @test "fld2" in cdef.fnames

    Containers.parse_container_fields!(cdef, [:B, 1, 2, 3], Val(:call))
    @test :B in cdef.ftypes
    @test "fld3" in cdef.fnames
end

@testset "parse_container_fields__tuple" begin
    cdef = Containers.ContainerDef{Containers.DefaultContainerParameters}("Test")

    Containers.parse_container_fields!(
        cdef, (:A, :(B(1)), :("testa" → A), :("testb" → B(2))), Val(:tuple)
    )
    @test :A in cdef.ftypes
    @test "fld1" in cdef.fnames
    @test :B in cdef.ftypes
    @test "fld2" in cdef.fnames
    @test "testa" in cdef.fnames
    @test "testb" in cdef.fnames
    @test cdef.fnum[] == 4
end

# ---
# Args

@testset "parse_container_args!__basecase" begin
    cdef = Containers.ContainerDef{Containers.DefaultContainerParameters}("Test")
    Containers.parse_container_args!(cdef, missing, missing)

    @test isempty(cdef.fnames)
    @test isempty(cdef.ftypes)
    @test isempty(cdef.finsta)
end

@testset "parse_container_args!__block" begin
    cdef = Containers.ContainerDef{Containers.DefaultContainerParameters}("Test")
    cdef.par.init = true
    toparse = Base.remove_linenums!(
        quote
            "testa" → A(2)
            B(3)
        end,
    )
    Containers.parse_container_args!(cdef, toparse.args, Val(:block))
    @test :A in cdef.ftypes
    @test "testa" in cdef.fnames
    @test :(A(2)) in cdef.finsta
    @test :B in cdef.ftypes
    @test "fld2" in cdef.fnames
end

# ---
# Parameters

@testset "parse_container_parameters!" begin
    cdef = Containers.ContainerDef{Containers.DefaultContainerParameters}("Test")

    # basecase
    Containers.parse_container_parameters!(cdef, missing, missing)

    @test isempty(cdef.fnames)
    @test isempty(cdef.ftypes)
    @test isempty(cdef.finsta)
    @test cdef.par.init == false
    @test cdef.par.parenttype == :AbstractContainer

    # set parameter
    Containers.parse_container_parameters!(cdef, Expr(:(=), :init, true))
    @test cdef.par.init
end
