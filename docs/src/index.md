```@meta
CurrentModule = Containers
```

# Containers.jl
Documentation for [Containers.jl](https://gitlab.com/astronaut-tools/julia/core/Containers).

## Design Motivations & Philosophy

### A Performance Issue

When dealing with multiple data types, often comes the problem to organise them into some
kind of container. Think about the case in which we have an abstract type and its concrete
subtypes:

```julia
abstract type AbstractParent end

struct A <: AbstractParent
    v::Vector
end

struct B <: AbstractParent
    v::Vector
end

struct C
    x::Number
end
```

```@setup types

abstract type AbstractParent end

struct A <: AbstractParent
    v::Vector
end

struct B <: AbstractParent
    v::Vector
end

struct C
    x::Number
end

v = [A(zeros(3)), B(zeros(3))]
vA = [A(zeros(3)), A(zeros(3))]
v2 = [A(zeros(3)), B(zeros(3)), C(1.0)]

@inbounds function getval(vi)
    return vi[1].v[1]
end
```

and we want to organize the instances within an vector-like structure.
The direct use of a `Vector` type would be inefficient in this case since its
instace would result in a abstract vector type:

```@example types
v = [A(zeros(3)), B(zeros(3))]
```

or, in case the elements are not associated to the same parent to a vector of `Any`:
```@example types
v2 = [A(zeros(3)), B(zeros(3)), C(1.0)]
```

Both cases are largely undesired from the performance point of view, because any operation
would allocate something into memory. For example, in the first case, let's assume we want
to write a function to get a value within the `v` vector contained in `A` or `B`:

```julia
@inbounds function getval(vi)
    return vi[1].v[1]
end
```

Let's then benchmark this simple operation:

```julia-repl
julia> @benchmark getval($v)
BenchmarkTools.Trial: 10000 samples with 1000 evaluations.
 Range (min … max):  31.621 ns … 867.008 ns  ┊ GC (min … max): 0.00% … 96.08%
 Time  (median):     33.290 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   35.954 ns ±  15.665 ns  ┊ GC (mean ± σ):  0.68% ±  1.66%

  ▂▅█▇▄▂    ▂▁▅▅▄▃▂▃▁▁                                         ▂
  ████████▆█████████████▇▇▆▅▅▆▇▆▆▄▅▄▃▄▅▆▇▇▆▆▆▆▄▄▃▁▄▄▄▅▆▅▅▅▅▃▅▄ █
  31.6 ns       Histogram: log(frequency) by time      64.2 ns <

 Memory estimate: 16 bytes, allocs estimate: 1.
```

This is something **very undesired** since, at every call of `getval`, the vector `v` contained
in either `A` or `B` is allocated before getting its first element.
Indeed, constructing a concrete vector:

```@example types
vA = [A(zeros(3)), A(zeros(3))]
```

its performances results way better than the abstract one (approx 15 times faster for this
simple example):

```julia-repl
julia> @benchmark getval($vA)
BenchmarkTools.Trial: 10000 samples with 1000 evaluations.
 Range (min … max):  2.396 ns … 56.949 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     2.409 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   2.554 ns ±  1.368 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  █▄      ▆▄  ▂▁                                             ▁
  ███▇▁▁▁▅██▇▇██▅▄▄▆▄▃▃▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▃▁▁▁▁▁▃▁▄ █
  2.4 ns       Histogram: log(frequency) by time     3.39 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```

### Goal

The goal of this package is then to create **efficient containers for mixed-type data**.

## API

### Public

```@autodocs
Modules = [Containers]
Private = false
Order = [:macro]
```

### Private

```@autodocs
Modules = [Containers]
Order = [:type, :function, :constant]
```
