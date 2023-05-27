using MixedTypesContainers
using Documenter

const CI = get(ENV, "CI", "false") == "true"

makedocs(;
    authors="Andrea Pasquale <andrea.pasquale@polimi.it>",
    sitename="MixedTypesContainers.jl",
    modules=[MixedTypesContainers],
    format=Documenter.HTML(; prettyurls=CI, highlights=["yaml"], ansicolor=true),
    pages=[
        "Home" => "index.md",
        "Design" => "design.md"
    ],
    clean=true,
)

deploydocs(;
    repo="github.com/JuliaSpaceMissionDesign/MixedTypesContainers.jl", branch="gh-pages"
)