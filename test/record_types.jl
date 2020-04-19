using Test
using AutoPreallocation
using AutoPreallocation: AllocationRecord, record_alloc!

@testset "isequal and hash" begin
    record1 = AllocationRecord()
    record_alloc!(record1, ones(3,7))
    record_alloc!(record1, zeros(40))

    record2 = AllocationRecord()
    record_alloc!(record2, zeros(3,7))
    record_alloc!(record2, ones(40))

    @test record1 == record2
    @test isequal(record1, record2)
    @test hash(record1) === hash(record2)

    @test record1 != AllocationRecord()
    @test !isequal(record1, AllocationRecord())
end


@testset "show" begin
    record = AllocationRecord()
    record_alloc!(record, ones(3,7))
    record_alloc!(record, zeros(40))

    @test repr(record) == "AutoPreallocation.AllocationRecord(\n" *
        "    [Array{Float64,2}(undef, (3, 7)), Array{Float64,1}(undef, (40,))],\n" *
        "    [(3, 7), (40,)]\n" *
        ")"

    # Check canon requirement of a good repr:
    @test eval(Meta.parse(repr(record))) == record
end

@testset "reinitialize" begin
    @testset "resizing up: maxsize = $maxsize" for maxsize in (0, 64, 64^3)
        record = AllocationRecord()
        record_alloc!(record, ones(maxsize))

        # Access preallocated item direct to mimic resizing it
        @assert length(record.allocations[1]) == maxsize
        empty!(record.allocations[1]) # shrink it down
        @assert length(record.allocations[1]) == 0
        @test (@ballocated reinitialize!($record)) == 0
        @test length(record.allocations[1]) == maxsize
    end

    @testset "resizing down: maxsize = $maxsize" for maxsize in (0, 64, 64^3)
        record = AllocationRecord()
        record_alloc!(record, Int[])

        # Access preallocated item direct to mimic resizing it
        @assert length(record.allocations[1]) == 0
        append!(record.allocations[1], ones(maxsize)) # grow it
        @assert length(record.allocations[1]) == maxsize
        @test (@ballocated reinitialize!($record)) == 0
        @test length(record.allocations[1]) == 0
    end
end
