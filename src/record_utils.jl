struct FrozenAllocationRecord{A,S} <: AbstractAllocationRecord
    allocations::A
    initial_sizes::S
end

function FrozenAllocationRecord(record)
    return FrozenAllocationRecord(Tuple(record.allocations), Tuple(record.initial_sizes))
end

"""
    freeze(record)

Freezes an allocation `record`, to not allow new allocations to be added.
This converts the memory of the what happenned to be stored as a `Tuple`.
This could give better performance during replay; or it could give worse.  
"""
freeze(record) = FrozenAllocationRecord(record)

"""
    reinitialize!(record)

Reset all arrays in the allocation `record` back to their initial sizes.
"""
function reinitialize!(record)
    for ii in eachindex(record.allocations)
        alloc = record.allocations[ii]
        sz = record.initial_sizes[ii]
        if size(alloc) !== sz
            # fix any vectors that were e.g. `push!`ed to.
            resize!(alloc, sz)
        end
    end
    return record
end
