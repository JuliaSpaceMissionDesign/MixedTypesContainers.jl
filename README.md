[![Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://astronaut-tools.gitlab.io/julia/core/Containers/latest/)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![pipeline status](https://gitlab.com/astronaut-tools/julia/core/Containers/badges/master/pipeline.svg)](https://gitlab.com/astronaut-tools/julia/core/Containers/-/commits/master)
[![coverage report](https://gitlab.com/astronaut-tools/julia/core/Containers/badges/master/coverage.svg)](https://gitlab.com/astronaut-tools/julia/core/Containers/-/commits/master)

# Containers.jl

*An efficient library for mixed-types containers.*

## Quickstart

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