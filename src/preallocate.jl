export preallocate

struct PreallocatedMethod{F, Args <: Tuple, N, R}
    f::F
    replay_ctxs::NTuple{N, R} # one replay context per thread

    function PreallocatedMethod{F, Args}(f::F, ctxs::NTuple{N, R}) where {F, Args, N, R}
        new{F, Args, N, R}(f, ctxs)
    end
end

function PreallocatedMethod(f::F, xs...) where F
    x, record = record_allocations(f, xs...)
    record = freeze(record)
    ctxs = ntuple(Threads.nthreads()) do ii
        new_replay_ctx(ii == 1 ? record : copy(record))
    end
    return PreallocatedMethod{F, typeof(xs)}(f, ctxs)
end

function (f::PreallocatedMethod)(xs...)
    ctx = f.replay_ctxs[Threads.threadid()]
    ctx.metadata.step[] = 1
    return Cassette.overdub(ctx, f.f, xs...)
end

"""
    preallocate(f, xs...)

Return the first run result and a preallocated version of the corresponding method of
callable object `f` given its argument. Note the behaviour of both the method generated record
and the method will be freezed, you shouldn't feed this function with a dynamic allocation
method.
"""
function preallocate(f::F, xs...) where F
    x, record = record_allocations(f, xs...)
    record = freeze(record)
    records = (ntuple(_->copy(record), Threads.nthreads() - 1)..., record)
    ctx = new_replay_ctx.(records)
    return x, PreallocatedMethod{F, typeof(xs)}(f, ctx)
end

function Base.show(io::IO, f::PreallocatedMethod{F, Args}) where {F, Args}
    print(io, "preallocate(", f.f)

    for each in Args.parameters
        print(io, ", ::", each)
    end

    print(io, ")")
end
