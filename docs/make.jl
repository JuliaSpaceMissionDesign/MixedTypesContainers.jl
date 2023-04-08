using Containers
using Documenter

DocMeta.setdocmeta!(Containers, :DocTestSetup, :(using Containers); recursive=true)

const CI = get(ENV, "CI", "false") == "true"

makedocs(;
    modules=[Containers],
    authors="Andrea Pasquale <andrea.pasquale@polimi.it> and contributors",
    repo="https://gitlab.com/astronaut-tools/julia/core/Containers/blob/{commit}{path}#{line}",
    sitename="Containers.jl",
    format=Documenter.HTML(;
        prettyurls=CI,
        canonical="https://astronaut-tools.gitlab.io/julia/core/Containers",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md"
        "Design" => "design.md"
        "API" => "api.md"
        ],
)
