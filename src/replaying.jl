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

function avoid_allocations(record, f, args...; kwargs...)
    ctx = new_replay_ctx(record)
    return Cassette.overdub(ctx, f, args...; kwargs...)
end

struct PreallocatedFunction{F}
    f::F
    ctx::Vector{Dict{Tuple, ReplayCtx}}  # maps from argument types to the ReplayCtx
    PreallocatedFunction(f) = new{typeof(f)}(f, [Dict{Tuple, ReplayCtx}() for _ in 1:Threads.nthreads()])
end

@generated function (f::PreallocatedFunction)(xs...)
    return quote
        if haskey(f.ctx[Threads.threadid()], $xs)
            ctx = f.ctx[Threads.threadid()][$xs]
            # step = ctx.metadata.step::Ref{Int}
            ctx.metadata.step[] = 1
            return Cassette.overdub(ctx, f.f, xs...)
        else
            x, record = record_allocations(f.f, xs...)
            ctx = AutoPreallocation.new_replay_ctx(record)
            f.ctx[Threads.threadid()][$xs] = ctx
            return x
        end
    end
end

"""
    preallocate(f)

Preallocate a function. This will preallocate the allocation behaviour of the function by creating
a [`PreallocatedFunction`](@ref). This function will record all the allocations at the first run,
then in the following run, it will not allocate anymore.
"""
preallocate(f) = PreallocatedFunction(f)

Base.show(io::IO, f::PreallocatedFunction) = print(io, "preallocate(", f.f, ")")
