export preallocate

struct PreallocatedMethod{F, Args <: Tuple, N, R}
    f::F
    replay_ctxs::NTuple{N, R} # one replay context per thread

    function PreallocatedMethod{F, Args}(f::F, ctxs::NTuple{N, R}) where {F, Args, N, R}
        new{F, Args, N, R}(f, ctxs)
    end
end

function (f::PreallocatedMethod)(xs...)
    ctx = f.replay_ctxs[Threads.threadid()]
    reinitialize!(ctx.metadata)
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
    ctxs = ntuple(Threads.nthreads()) do k
        new_replay_ctx(k == 1 ? copy(record) : record)
    end
    return x, PreallocatedMethod{F, typeof(xs)}(f, ctxs)
end

function Base.show(io::IO, f::PreallocatedMethod{F, Args}) where {F, Args}
    print(io, "preallocate(", f.f)

    for each in Args.parameters
        print(io, ", ::", each)
    end

    print(io, ")")
end
