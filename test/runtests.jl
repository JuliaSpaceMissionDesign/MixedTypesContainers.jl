using Test
using MixedTypesContainers

@testset "MixedTypesContainers.jl" verbose = true begin
    for file in ["types.jl", "parse.jl", "container.jl", "iteration.jl"]
        include(file)
    end
end;