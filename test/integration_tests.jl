using AutoPreallocation
using BenchmarkTools
using Test

# functions to test on
f_ones() = ones(64)
f_matmul() = ones(32,64) * ones(64, 2)

f_matmul_noprealloc() = ones(32,64) * @no_prealloc(ones(64, 2))

@testset "ones example" begin
    @assert (@ballocated f_ones()) === 624
    val, record = record_allocations(f_ones)
    @test (@ballocated avoid_allocations($record, f_ones)) <= 64
end

@testset "matmul example" begin
    @assert (@ballocated f_matmul()) === 18_304
    val, record = record_allocations(f_matmul)
    # NOTE: (@Roger-luo) not sure why this is 256 on my machine
    @test (@ballocated avoid_allocations($record, f_matmul)) <= 352

    f = preallocate(f_matmul)
    @test (@ballocated $f()) <= 352
end

@testset "noprealloc example" begin
    @assert (@ballocated f_matmul_noprealloc()) === 18_304
    val, record = record_allocations(f_matmul_noprealloc)
    @test length(record.allocations) == 2
    @test record.initial_sizes == [(32, 64), (32, 2)]
    @test (@ballocated avoid_allocations($record, f_matmul_noprealloc)) <= 1520
end

@testset "check thread-safe" begin
    f(x, y) = x * y
    results = Vector{Any}(undef, 4)
    As = [rand(4, 4) for _ in 1:4]
    Bs = [rand(4, 4) for _ in 1:4]
    _, pf = preallocate(As[1], Bs[1])
    Threads.@threads for k in 1:4
        results[k] = pf(As[k], Bs[k])
    end

    # if it's not thread-safe, the result
    # will be modified by other multiplications
    # since they will share the same memory
    for k in 1:4
        @test results[k] ≈ f(As[k], Bs[k])
    end
end