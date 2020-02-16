using Documenter, AutoPreallocation

makedocs(;
    modules=[AutoPreallocation],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/oxinabox/AutoPreallocation.jl/blob/{commit}{path}#L{line}",
    sitename="AutoPreallocation.jl",
    authors="Lyndon White",
    assets=String[],
)

deploydocs(;
    repo="github.com/oxinabox/AutoPreallocation.jl",
)
