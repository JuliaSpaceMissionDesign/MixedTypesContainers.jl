
struct MyA 
    x::Float64
end

struct MyB 
    x::Float64
end

c = @container "MyTestContainer" begin
    "a" → MyA(1.0)
    "b" → MyB(2.0)
end

@iterated function f(c::AbstractContainer{N}) where N 
    val = 0.0 
    @unwrap for i in 1:N 
        val += c[i].x
    end
    val
end

@testset "Container iterations" begin
    @test f(c) == 3.0
end

