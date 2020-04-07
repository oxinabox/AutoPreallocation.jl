using Documenter, AutoPreallocation

makedocs(;
    modules=[AutoPreallocation],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/oxinabox/AutoPreallocation.jl",
    sitename="AutoPreallocation.jl",
    authors=["Lyndon White", "Roger Luo"],
)

deploydocs(;
    repo="github.com/oxinabox/AutoPreallocation.jl",
)
