using Documenter, AutoPreallocation

makedocs(;
    modules=[AutoPreallocation],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/oxinabox/AutoPreallocation.jl",
    sitename="AutoPreallocation.jl",
    authors="Lyndon White",
)

deploydocs(;
    repo="github.com/oxinabox/AutoPreallocation.jl",
)
