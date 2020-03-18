# In this file we define special-cases to prevent Cassette related inference issues

const BLACK_LIST = (
    Base.promote_op, Base.to_shape,
    Core.getfield,
    Core.:(===),
    Base.iterate,
    Broadcast.broadcasted,
    Broadcast.preprocess,
    Broadcast.combine_axes,
    Base.not_int,
    Base.size,
    Base.haskey,
    Base.reduced_indices,
    LinearAlgebra.gemv!,
    Tuple,
    # skip all AutoPreallocation APIs
    preallocate,
    avoid_allocations,
    freeze,
    record_allocations,
)

for F in BLACK_LIST
    @eval @inline Cassette.overdub(ctx::RecordingCtx, f::typeof($F), xs...) = f(xs...)
    @eval @inline Cassette.overdub(ctx::ReplayCtx, f::typeof($F), xs...) = f(xs...)
end

@inline Cassette.overdub(ctx::RecordingCtx, ::Type{Val}, x) = Val(x)
@inline Cassette.overdub(ctx::ReplayCtx, ::Type{Val}, x) = Val(x)

@inline Cassette.overdub(ctx::RecordingCtx, ::typeof(getindex), x::IdDict, key) = getindex(x, key)
@inline Cassette.overdub(ctx::ReplayCtx, ::typeof(getindex), x::IdDict, key) = getindex(x, key)

@inline Cassette.overdub(ctx::RecordingCtx, f::PreallocatedFunction, xs...) = f(xs...)
@inline Cassette.overdub(ctx::ReplayCtx, f::PreallocatedFunction, xs...) = f(xs...)
