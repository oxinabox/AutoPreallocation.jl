struct AllocationReplay
    allocations::Vector{Array}
    step::Ref{Int}
end

function AllocationReplay(record::AllocationRecord)
    allocations = record.allocations
    for ii in eachindex(record.allocations)
        alloc = record.allocations[ii]
        sz = record.initial_sizes[ii]
        if size(alloc) !== sz
            # fix any vectors that were e.g. `push!`ed to.
            resize!(alloc, sz)
        end
    end
    return AllocationReplay(allocations, Ref(1))
end

Cassette.@context ReplayCtx
new_replay_ctx(record::AllocationRecord) = new_replay_ctx(AllocationReplay(record))
function new_replay_ctx(replay::AllocationReplay)
    replay.step[] = 1
    return ReplayCtx(metadata=replay)
end


@inline function next_scheduled_alloc!(replay::AllocationReplay)
    alloc = replay.allocations[replay.step[]]
    replay.step[]+=1
    return alloc
end
@inline next_scheduled_alloc!(ctx::ReplayCtx) = next_scheduled_alloc!(ctx.metadata)


@inline function Cassette.overdub(
    ctx::ReplayCtx, ::Type{Array{T,N}}, ::UndefInitializer, dims
)::Array{T,N} where {T,N}
    scheduled = next_scheduled_alloc!(ctx)

    # Commented out until we can workout how to do this without allocations on the happy path
    # TODO: reenable this
    #==
    if size(scheduled) !== dims || eltype(scheduled) !== T
        @warn "Allocation reuse failed. Indicates value dependent allocations." step=ctx.metadata.step[] expected_T=eltype(scheduled) actual_T=T expected_size=size actual_size=dims
        # Fallback to just doing the allocation
        return Array{T,N}(undef, dims)
    end
    ==#

    return scheduled
end


function avoid_alloctions(record, f, args...; kwargs...)
    ctx = new_replay_ctx(record)
    return Cassette.recurse(ctx, f, args...; kwargs...)
end
