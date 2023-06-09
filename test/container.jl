@testset "parse_container" verbose=true begin
    
    @testset "@container 'Name' (T1, T2, T3, ...)" begin
        cdef = MixedTypesContainers.parse_container(:(@container "Name" (A, B, C, D)).args[3:end])
        @test cdef.fnum[] == 4
        @test cdef.fnames == ["FIELD1", "FIELD2", "FIELD3", "FIELD4"]
        @test cdef.ftypes == [:A, :B, :C, :D]
        @test !MixedTypesContainers.check_field_instance(cdef)
    end

    @testset "@container 'Name' (T1(..), T2(..), ...)" begin
        cdef = MixedTypesContainers.parse_container(:(@container "Name" (A(1, 3), B(), C(), D(3))).args[3:end])
        @test cdef.fnum[] == 4
        @test cdef.fnames == ["FIELD1", "FIELD2", "FIELD3", "FIELD4"]
        @test cdef.ftypes == [:A, :B, :C, :D]
        @test cdef.finsta == [:(A(1,3)), :(B()), :(C()), :(D(3))]
        @test MixedTypesContainers.check_field_instance(cdef)
    end

    @testset "@container 'Name' ('a' → T1, 'b' → T2, ...)" begin
        cdef = MixedTypesContainers.parse_container(:(@container "Name" ("a" → A, "b" → B, "c" → C)).args[3:end])
        @test cdef.fnum[] == 3
        @test cdef.fnames == ["a", "b", "c"]
        @test cdef.ftypes == [:A, :B, :C]
        @test !MixedTypesContainers.check_field_instance(cdef)
    end

    @testset "@container 'Name' ('a' → T1(..), 'b' → T2(..), ...)" begin
        cdef = MixedTypesContainers.parse_container(:(@container "Name" ("a" → A(), "b" → B(1.0), "c" → C())).args[3:end])
        @test cdef.fnum[] == 3
        @test cdef.fnames == ["a", "b", "c"]
        @test cdef.ftypes == [:A, :B, :C]
        @test MixedTypesContainers.check_field_instance(cdef)
        @test cdef.finsta == [:(A()), :(B(1.0)), :(C())]
    end

    @testset "@container 'Name' begin T... end" begin
        expr = :(
            @container "Name" begin 
                A
                B
            end
        )
        cdef = MixedTypesContainers.parse_container(expr.args[3:end])
        @test cdef.fnum[] == 2
        @test cdef.fnames == ["FIELD1", "FIELD2"]
        @test cdef.ftypes == [:A, :B]
        @test !MixedTypesContainers.check_field_instance(cdef)
    end

    @testset "@container 'Name' begin 'f' → T()  ... end" begin
        expr = :(
            @container "Name" begin 
                "a" → A()
                "b" → B(1,2,3)
            end
        )
        cdef = MixedTypesContainers.parse_container(expr.args[3:end])
        @test cdef.fnum[] == 2
        @test cdef.fnames == ["a", "b"]
        @test cdef.ftypes == [:A, :B]
        @test MixedTypesContainers.check_field_instance(cdef)
    end

    @testset "Recursive call (without instances)"  begin
        expr = :(
            @container "Name" begin
                "a" → A
                "b" → @container "SubName" begin
                    "as" → A
                    "bs" → @container "SubSubName" begin
                        "as2" → A
                    end
                end
                "c" → C
            end
        )
        cdef = MixedTypesContainers.parse_container(expr.args[3:end])
        @test cdef.fnames == ["a", "b", "c"]
        @test cdef.ischild == [false, true, false]
        @test cdef.ftypes == [:A, :SubName, :C]
        @test !MixedTypesContainers.check_field_instance(cdef)

        @test length(cdef.childrens) == sum(cdef.ischild)
        @test cdef.childrens[1].name == :SubName
        @test cdef.childrens[1].fnames == ["as", "bs"]
        @test cdef.childrens[1].ftypes == [:A, :SubSubName]
        @test MixedTypesContainers.haschildrens(cdef.childrens[1])
    end

    @testset "Recursive call (with instances)"  begin
        expr = :(
            @container "Name" begin
                "a" → A(1)
                "b" → @container "SubName" begin
                    "as" → A(2)
                    "bs" → @container "SubSubName" begin
                        "as2" → A(3)
                    end
                end
                "c" → C(1,2,3)
            end
        )
        cdef = MixedTypesContainers.parse_container(expr.args[3:end])
        @test cdef.fnames == ["a", "b", "c"]
        @test cdef.ischild == [false, true, false]
        @test cdef.ftypes == [:A, :SubName, :C]
        @test cdef.finsta == [:(A(1)), :(SubName()), :(C(1,2,3))]
        @test MixedTypesContainers.check_field_instance(cdef)

        @test length(cdef.childrens) == sum(cdef.ischild)
        @test cdef.childrens[1].name == :SubName
        @test cdef.childrens[1].fnames == ["as", "bs"]
        @test cdef.childrens[1].ftypes == [:A, :SubSubName]
        @show MixedTypesContainers.haschildrens(cdef.childrens[1])
        @test MixedTypesContainers.check_field_instance(cdef.childrens[1])
    end

    @testset "Recursive call (errors)" begin
        expr = :(
            @container "Name" begin
                "a" → A()
                "b" → @container "SubCont" begin
                    "as" → A
                end
                "c" → C()
            end
        )
        @test_throws ArgumentError MixedTypesContainers.parse_container(expr.args[3:end])
    end

    @testset "Container parameters" begin
        expr = :(
            @container "Name" parenttype=TestSymbol init=true begin
                A(1)
            end
        )
        cdef = MixedTypesContainers.parse_container(expr.args[3:end])
        @test cdef.par.parenttype == :TestSymbol
        @test cdef.par.init 
    end

end;


struct A 
    x::Float64 
end 
struct B 
    x::Float64
end

@container "TestContainer" begin
    "a" → B(1.0)
    "b" → A(1.0)
    "c" → A(1.0)
    "d" → A(1.0)
    "e" → B(1.0)
    "f" → B(1.0)
end

@testset "create_container" begin
    c = TestContainer()
    @test c.data == (a = B(1.0), b = A(1.0), c = A(1.0), d = A(1.0), e = B(1.0), f = B(1.0))
    @test c.typemap[:A] == [2, 3, 4]
    @test c.typemap[:B] == [1, 5, 6]
end