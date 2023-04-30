```@meta
CurrentModule = Containers
```

# Containers.jl
Documentation for [Containers.jl](https://gitlab.com/astronaut-tools/julia/core/Containers).

## Container creation

All you need to know to create a new mixed-type container using `Containers.jl` is how to use
the `@container` macro. The user have the possibility to create both **named** and **unnamed**
fields within the user-defined container. In the latter case, a default name will be assigned
during the container creation.

The basic syntax to be used to define a container is:

```julia
@container "ContainerName" begin
    "field-1" → T1,
    "field-2" → T2(1.0),
    T1(1.0),
    T2
end
```

Here `ContainerName` is the user-defined name of the container.
In the `begin ... end` block the container's field are instead listed.
Four possible formats are available:

- `"field-1" → T1` -- field defined as type `T1` with name `field-1`;
- `"field-1" → T2(1.0)` -- field defined as type `T2` with name `field-2`;
- `T1(1.0)` -- unnamed filed with type `T1`;
- `T2` -- unnamed filed with type `T2`;

You can also use a type-only definition of the field or a type constructor.
In the latter case, there is the possibility to create an empty constructor for the new
container, where all the fields initialization is handled by the container constructor itself.

### Container parameters

While the basic use is straight forward, there is the possibility to configure the container
exploiting the _container parameters_. These shall be inserted right before the container fields
and shall be correspond to a field of a `AbstractContainerParameters` subtype. The default
subtype is `DefaultContainerParameters` which contains the following parameters and default values:

- `init::Bool` -- create an empty constructor that initialize the container and its fields. Default is `false`.

```julia
c = @container "ContainerName" init=true begin
    "field-1" → T1(1.0),
    "field-2" → T2(1.0),
    T1(1.0),
    T2(2.0)
end
```

In case the `init` parameter is used, the `@container` macro returns an initialized container. As in the 
example above, it can be stored in a variable already by assignment.

- `parenttype::Symbol` -- parent (abstract) type for the container. Default is `:AbstractContainer`.

```julia
@container "ContainerName" parenttype = :JustAnotherParent begin
    "f1" → T1
end

# This corresponds to:

struct ContainerName <: JustAnotherParent
    data::NamedTuple{(:f1, ), Tuple{T1}}
end
```

----

## Container iteration

The possibility to store mixed-types within a single container is end in itself if not comes
along with an efficient way to iterate it. Therefore, `Containers.jl` containes a set of
utility tools which are designed to allocation-freely iterate the user-defined containers. 
To best introduce their use, let's consider and example where a user defined container 
`Container` is created and a function `test_function` is defined as:

```julia
function test_function(c::Container)
    val = 0.0
    for i in eachindex(c)
        c[i].x = 1.0i
        val += iterate_function(c[i])
    end
    return val
end
```

This function modify a (common) field of the container and apply `iterate_function` to 
compute a `val` variable, which is returned as output. The main issue here is associated 
to the fact that, being each element of the container of a different type, this function
allocates. 

### Function barriers method 

One possible solution is to exploit [function barriers](https://docs.julialang.org/en/v1/manual/performance-tips/#kernel-functions) to avoid it at the cost of a very _structured_
and less portable/maintainable code. As additional drawback, poor performances of this 
approach are observed. For comparison, consider a 2 elements container and a `iterate_function`
that simply reads a value within a container element:

```julia-repl
julia> @benchmark test_barrier($c)
BenchmarkTools.Trial: 10000 samples with 995 evaluations.
 Range (min … max):  27.461 ns …   2.720 μs  ┊ GC (min … max):  0.00% … 98.28%
 Time  (median):     29.851 ns               ┊ GC (median):     0.00%
 Time  (mean ± σ):   39.396 ns ± 144.435 ns  ┊ GC (mean ± σ):  21.35% ±  5.74%

   ▆▆█▃                                                         
  ▄████▇▅▅▆▄▃▃▃▃▂▂▂▂▂▂▂▂▂▂▂▂▂▁▂▁▂▂▂▂▂▁▁▂▂▂▂▂▂▂▂▂▂▂▁▂▂▂▂▂▂▂▂▂▁▂ ▃
  27.5 ns         Histogram: frequency by time         66.8 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```

### Unwrapped iteration method

Within `Containers.jl` and alternative approach is adopted by means of the introduction of
two macros: `@unwrap` and `@iterated`. These have two precise roles:

- `@unwrap`: decorate `for` loops. It transforms the expression in a specialized,
    non-allocating one. For example, with reference to the `test_function` the `for` loop 
    can be transformed to:

```julia 
@unwrap for i in eachindex(c)
    c[i].x = 1.0i
    val += iterate_function(c[i])
end
```

- `@iterated`: decorate a `function` that containes `Container`'s iterations. It is used
    to tranform the part of the function associated to the `Container`. For example, with
    reference to the `test_function`:

```julia
@iterated function test_iterated(c::ExampleContainer{N}) where {N}
    val = 0.0
    @unwrap for i in 1:N
        c[i].x = 1.0i
        val += iterate_function(c[i])
    end
    return val
end
```

!!! warning 
    Note that the use of `@iterated` comes always with the one of `@unwrap` as the latter transforms
    the `for` loop while the former the function itself. Note also that some modifications have
    been done to the new function:

    - The function signature is now parametric in `N`. Here `N` represent the dimension of the 
        container and is a parameter automatically associated to the `AbstractContainer` 
        subtypes during their generation.

    - The `for` loop is still _unwrapped_ with `@unwrap` but the iteration is specified using
        the parametric argument `N`.

    These last two modification **shall** be applied to exploit `@iterated` functionalities
    at the current version of `Containers.jl`. This may change in future.

With this approach, just with some simple adjustments to the code, a non-allocating, high-performance
version of the function can be obtained resulting in (more than) a order of magnitude 
speed-up:
```julia-repl
julia> @benchmark test_iterated($c)
BenchmarkTools.Trial: 10000 samples with 1000 evaluations.
 Range (min … max):  1.496 ns … 3.989 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     1.508 ns             ┊ GC (median):    0.00%
 Time  (mean ± σ):   1.511 ns ± 0.042 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

      ▁▁▃▄▃ ▅▆▆██▇▇▅▂                                        
  ▂▃▄▆█████▁█████████▁█▅▄▃▂▂▂▁▁▂▂▁▁▁▁▂▂▂▁▂▂▂▂▃▂▂▂▁▃▃▃▃▃▃▃▃▂ ▄
  1.5 ns         Histogram: frequency by time       1.55 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```