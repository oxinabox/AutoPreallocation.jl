using AutoPreallocation
using BenchmarkTools
using Test

# Its not worth the effort of writing these tests to work both on 64bit and 32bit.
# Pointer size basically gets counted in a ton of things we measure, and distangling
# number of pointer allocations from content allocations is too much work.
sizeof(1) == 8 || error("These tests cn only be run on 64-bit systems.")

const files = (
    "integration_tests.jl",
    "record_types.jl",
    "readme_examples.jl"
)
@testset "AutoPreallocation.jl" begin
    @testset "$file" for file in files
        include(file)
    end
end
