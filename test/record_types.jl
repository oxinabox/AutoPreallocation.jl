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
