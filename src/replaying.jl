struct AllocationReplay{A}
    allocations::A
    step::Ref{Int}
end

AllocationReplay(record) = AllocationReplay(record.allocations, Ref(1))

Cassette.@context ReplayCtx
new_replay_ctx(record) = new_replay_ctx(AllocationReplay(record))
function new_replay_ctx(replay::AllocationReplay)
    #replay.step[] = 1
    return Cassette.disablehooks(ReplayCtx(metadata=replay))
end


@inline function next_scheduled_alloc!(replay::AllocationReplay)
    step = replay.step[] :: Int
    alloc = replay.allocations[step] :: Array
    replay.step[] = step + 1
    return alloc
end
@inline next_scheduled_alloc!(ctx::ReplayCtx) = next_scheduled_alloc!(ctx.metadata)

@inline function Cassette.overdub(
    ctx::ReplayCtx, ::Type{Array{T,N}}, ::UndefInitializer, dims
)::Array{T,N} where {T,N}
    scheduled = next_scheduled_alloc!(ctx) :: Array{T,N}

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


const BLACK_LIST = [
    Base.promote_op, Base.to_shape,
    Core.getfield,
    Core.:(===),
    Base.iterate,
    Broadcast.broadcasted,
    Broadcast.preprocess, Base.not_int,
    Base.size,
    Tuple,
]

for F in BLACK_LIST
    @eval @inline Cassette.overdub(ctx::RecordingCtx, f::typeof($F), xs...) = f(xs...)
    @eval @inline Cassette.overdub(ctx::ReplayCtx, f::typeof($F), xs...) = f(xs...)
end

function avoid_allocations(record, f, args...; kwargs...)
    ctx = new_replay_ctx(record)
    return Cassette.overdub(ctx, f, args...; kwargs...)
end

struct FrozenFunction{F}
    f::F
    ctx::Dict{Tuple, ReplayCtx}
    FrozenFunction(f) = new{typeof(f)}(f, Dict{Tuple, ReplayCtx}())
end

@generated function (f::FrozenFunction)(xs...)
    return quote
        if haskey(f.ctx, $xs)
            ctx = f.ctx[$xs]
            ctx.metadata.step[] = 1
            return Cassette.overdub(ctx, f.f, xs...)
        else
            x, record = record_allocations(f.f, xs...)
            ctx = AutoPreallocation.new_replay_ctx(record)
            f.ctx[$xs] = ctx
            return x
        end
    end
end

"""
    freeze(f)

Freeze a function. This will freeze the allocation behaviour of the function by creating
a [`FrozenFunction`](@ref). This function will record all the allocations at the first run,
then in the following run, it will not allocate anymore.
"""
freeze(f) = FrozenFunction(f)
