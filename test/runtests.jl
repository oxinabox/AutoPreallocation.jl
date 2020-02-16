using AutoPreallocation
using BenchmarkTools
using Test

# Its not worth the effort of writing these tests to work both on 64bit and 32bit.
# Pointer size basically gets counted in a ton of things we measure, and distangling
# number of pointer allocations from content allocations is too much work.
sizeof(1) == 8 || error("These tests cn only be run on 64-bit systems.")

# functions to test on
f_ones() = ones(64)
f_matmul() = ones(32,64) * ones(64, 2)

@testset "AutoPreallocation.jl" begin
    @testset "ones example" begin
        @assert (@ballocated f_ones()) === 624
        val, record = record_alloctions(f_ones)
        @test (@ballocated avoid_alloctions($record, f_ones)) == 80
    end

    @testset "matmul example" begin

        @assert (@ballocated f_matmul()) === 18_304
        val, record = record_alloctions(f_matmul)
        @test (@ballocated avoid_alloctions($record, f_matmul)) == 352
    end
end
