using Containers
using Documenter

const CI = get(ENV, "CI", "false") == "true"

makedocs(;
    authors="Andrea Pasquale <andrea.pasquale@polimi.it>",
    sitename="Containers.jl",
    modules=[Containers],
    format=Documenter.HTML(; prettyurls=CI, highlights=["yaml"], ansicolor=true),
    pages=[
        "Home" => "index.md"
    ],
    clean=true,
)

deploydocs(;
    repo="github.com/JuliaSpaceMissionDesign/Containers.jl", branch="gh-pages"
)