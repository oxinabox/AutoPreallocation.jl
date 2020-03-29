export preallocate

struct PreallocatedMethod{F, Args <: Tuple, N, R}
    f::F
    ctx::NTuple{N, R}

    function PreallocatedMethod{F, Args}(f::F, ctx::NTuple{N, R}) where {F, Args, N, R}
        new{F, Args, N, R}(f, ctx)
    end
end

function PreallocatedMethod(f::F, xs...) where F
    x, record = record_allocations(f, xs...)
    record = freeze(record)
    records = (ntuple(_->copy(record), Threads.nthreads() - 1)..., record)
    ctx = new_replay_ctx.(records)
    return PreallocatedMethod{F, typeof(xs)}(f, ctx)
end

function (f::PreallocatedMethod)(xs...)
    ctx = f.ctx[Threads.threadid()]
    # RL: Why this is not type stable at all?
    step = getfield(ctx.metadata, :step)::Base.RefValue{Int}
    setindex!(step, 1)::Base.RefValue{Int}
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
