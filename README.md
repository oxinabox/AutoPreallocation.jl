# AutoPreallocation

[![Build Status](https://travis-ci.com/oxinabox/AutoPreallocation.jl.svg?branch=master)](https://travis-ci.com/oxinabox/AutoPreallocation.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

**Have you ever wanted your code to allocate less?**
**Have you ever felt explictly preallocating everything was just too hard?**
**Have you ever thought: _"why not just reuse the allocated memory from last time"_?**
**Well look no further, friend.**

## How to use:

The simplest way of using this package is via only one function [`preallocate`](@ref), e.g

```julia
julia> using AutoPreallocation, BenchmarkTools

julia> A, B, C = (rand(1000, 1000) for _ in 1:3)
Base.Generator{UnitRange{Int64},var"#9#10"}(var"#9#10"(), 1:3)

julia> f(x, y, z) = x * y * z
f (generic function with 1 method)

julia> x, preallocated_f = preallocate(f, A, B, C);

julia> @btime f(A, B, C);
  25.684 ms (4 allocations: 15.26 MiB)

julia> @btime preallocated_f(A, B, C);
  26.077 ms (4 allocations: 144 bytes)
```

# License

MIT License
