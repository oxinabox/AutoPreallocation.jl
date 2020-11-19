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
    @test (@ballocated avoid_allocations($record, f_ones)) <= 80
end

@testset "matmul example" begin
    @assert (@ballocated f_matmul()) === 18_304
    val, record = record_allocations(f_matmul)
    # NOTE: (@Roger-luo) not sure why this is 256 on my machine
    @test (@ballocated avoid_allocations($record, f_matmul)) <= 352

    _, pf = preallocate(f_matmul)
    @test (@ballocated $pf()) <= 352
end

@testset "noprealloc example" begin
    @assert (@ballocated f_matmul_noprealloc()) === 18_304
    val, record = record_allocations(f_matmul_noprealloc)
    @test length(record.allocations) == 2
    @test record.initial_sizes == [(32, 64), (32, 2)]
    @test (@ballocated avoid_allocations($record, f_matmul_noprealloc)) <= 1520
end

@testset "resizing operations" begin
    function push_pop_test(a)
        x = [0, 0, 0]
        @test length(x) == 3
        push!(x, a)
        push!(x, 10a)
        @test length(x) == 5
        pop!(x)
        @test length(x) == 4
    end

    _, p_push_pop_test = preallocate(push_pop_test, 1)
    p_push_pop_test(2)  # check works on second call
    p_push_pop_test(3)  # check works on third call
    p_push_pop_test(4)  # check works on fourth call
end
