using AutoPreallocation
using BenchmarkTools
using Test

# functions to test on
f_ones() = ones(64)
f_matmul() = ones(32,64) * ones(64, 2)


@testset "ones example" begin
    @assert (@ballocated f_ones()) === 624
    val, record = record_allocations(f_ones)
    @test (@ballocated avoid_allocations($record, f_ones)) == 64
end

@testset "matmul example" begin
    @assert (@ballocated f_matmul()) === 18_304
    val, record = record_allocations(f_matmul)
    @test (@ballocated avoid_allocations($record, f_matmul)) == 256
end
