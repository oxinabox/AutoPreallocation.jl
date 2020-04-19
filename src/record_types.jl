abstract type AbstractAllocationRecord end
struct AllocationRecord <: AbstractAllocationRecord
    allocations::Vector{Array}
    initial_sizes::Vector{Any}  # collection of differently sizes tuples of integers
end
AllocationRecord() = AllocationRecord(Vector{Array}(), Vector{Any}())

struct FrozenAllocationRecord{A,S} <: AbstractAllocationRecord
    allocations::A
    initial_sizes::S
end

function FrozenAllocationRecord(record)
    return FrozenAllocationRecord(Tuple(record.allocations), Tuple(record.initial_sizes))
end

function Base.copy(record::AllocationRecord)
    return AllocationRecord(copy.(record.allocations), record.initial_sizes)
end

function Base.copy(record::FrozenAllocationRecord)
    return FrozenAllocationRecord(copy.(record.allocations), record.initial_sizes)
end

"""
    freeze(record)

Freezes an allocation `record`, to not allow new allocations to be added.
This converts the memory of the what happenned to be stored as a `Tuple`.
This could give better performance during replay; or it could give worse.
"""
freeze(record::AbstractAllocationRecord) = FrozenAllocationRecord(record)

"""
    reinitialize!(record)

Reset all arrays in the allocation `record` back to their initial sizes.
"""
function reinitialize!(record)
    for ii in eachindex(record.allocations)
        alloc = record.allocations[ii]
        sz = record.initial_sizes[ii]

        # only vectors can be resized, and
        # don't check `size(alloc)` as this allocates, unlike `length(alloc)`
        if ndims(alloc) == 1 && length(alloc) !== first(sz)
            # fix any vectors that were e.g. `push!`ed to.
            resize!(alloc, sz...)
        end
    end
    return record
end

# This can be use to write the record to file so that one can reuse it.
function Base.show(io::IO, record::AllocationRecord)
    allocs = join(("$(typeof(x))(undef, $(size(x)))" for x in record.allocations), ", ")
    sizes = join(record.initial_sizes, ", ")
    println(io, "$(@__MODULE__).AllocationRecord(")
    println(io, "    [$allocs],")
    println(io, "    [$sizes]")
    print(io, ")")
end

Base.hash(record::AbstractAllocationRecord, k::UInt) = hash(record.initial_sizes)
function Base.:(==)(r1::AbstractAllocationRecord, r2::AbstractAllocationRecord)
    return (
        r1.initial_sizes == r2.initial_sizes
        && eltype.(r1.allocations) == eltype.(r2.allocations)
    )
end
