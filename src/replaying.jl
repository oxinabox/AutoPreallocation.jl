struct AllocationReplay{A}
    record::A
    step::Base.RefValue{Int}
end

AllocationReplay(record) = AllocationReplay(record, Ref(1))

Cassette.@context ReplayCtx
new_replay_ctx(record) = new_replay_ctx(AllocationReplay(record))
function new_replay_ctx(replay::AllocationReplay)
    reinitialize!(replay)
    return Cassette.disablehooks(ReplayCtx(metadata=replay))
end

"""
    reinitialize!(replay::AllocationReplay)

Return all recorded allocations to original sizes, and reset to first step.
"""
function reinitialize!(replay::AllocationReplay)
    reinitialize!(replay.record)
    replay.step[] = 1
    return replay
end

@inline function next_scheduled_alloc!(replay::AllocationReplay)
    step = replay.step[] :: Int
    alloc = replay.record.allocations[step]
    replay.step[] = step + 1
    return alloc
end
@inline next_scheduled_alloc!(ctx::ReplayCtx) = next_scheduled_alloc!(ctx.metadata)

@inline function Cassette.overdub(
    ctx::ReplayCtx, ::Type{A}, ::UndefInitializer, dims...
)::A where {A<:Array}
    scheduled = next_scheduled_alloc!(ctx) :: A

    # Commented out until we can workout how to do this without allocations on the happy path
    # It seems like having any branch here makes it allocate
    # TODO: reenable this
    #==
    if  typeof(scheduled) !== Array{T,N} || size(scheduled) !== dims
        @warn "Allocation reuse failed. Indicates value dependent allocations." step=ctx.metadata.step[] expected_T=eltype(scheduled) actual_T=T expected_size=size actual_size=dims
        # Fallback to just doing the allocation
        return Array{T,N}(undef, dims)
    end
    ==#

    return scheduled
end

"""
    avoid_allocations(record, f, args...; kwargs...)

Avoid allocations stored in `record`. See also [`record_allocations`](@ref).
"""
function avoid_allocations(record, f, args...; kwargs...)
    ctx = new_replay_ctx(record)
    return Cassette.overdub(ctx, f, args...; kwargs...)
end
