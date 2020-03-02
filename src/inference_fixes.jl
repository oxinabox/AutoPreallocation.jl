# In this file we define special-cases to prevent Cassette related inference issues
using Zygote: @adjoint, _pullback, Context, cache
using Cassette
using Flux

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
)

for F in BLACK_LIST
    @eval @inline Cassette.overdub(ctx::RecordingCtx, f::typeof($F), xs...) = f(xs...)
    @eval @inline Cassette.overdub(ctx::ReplayCtx, f::typeof($F), xs...) = f(xs...)
end

@inline Cassette.overdub(ctx::RecordingCtx, ::Type{Val}, x) = Val(x)
@inline Cassette.overdub(ctx::ReplayCtx, ::Type{Val}, x) = Val(x)

@inline Cassette.overdub(ctx::RecordingCtx, ::typeof(getindex), x::IdDict, key) = getindex(x, key)
@inline Cassette.overdub(ctx::ReplayCtx, ::typeof(getindex), x::IdDict, key) = getindex(x, key)


function reset_cx!(cx::Context, ps)::Context
    for p in ps
        cache(cx)[p] = nothing
    end
    return cx
end

@inline function Cassette.overdub(ctx::RecordingCtx, ::typeof(Zygote.gradient), f, ps::Params)
    cx = Context()
    y, back = Cassette.overdub(ctx, _pullback, cx, f)
    reset_cx!(cx, ps)
    Cassette.overdub(ctx, back, Zygote.sensitivity(y))
    return Zygote.Grads(cx.cache)
end

@inline function Cassette.overdub(ctx::ReplayCtx, ::typeof(Zygote.gradient), f, ps::Params)
    cx = Context()
    y, back = Cassette.overdub(ctx, _pullback, cx, f)
    reset_cx!(cx, ps)
    Cassette.overdub(ctx, back, Zygote.sensitivity(y))
    return Zygote.Grads(cx.cache)
end

@inline function Cassette.overdub(ctx::RecordingCtx, ::typeof(_accum_param), cx::Context, x, Δ)
    haskey(cache(cx), x) || return
    x_cache = cache(cx)[x]
    new_x = Cassette.overdub(ctx, Zygote.accum, x_cache,Δ)
    cache(cx)[x] = new_x
    return
end

@inline function Cassette.overdub(ctx::ReplayCtx, ::typeof(_accum_param), cx::Context, x, Δ)
    haskey(cache(cx), x) || return
    x_cache = cache(cx)[x]
    new_x = Cassette.overdub(ctx, Zygote.accum, x_cache,Δ)
    cache(cx)[x] = new_x
    return
end

# preallocation patch for Flux
@inline function Cassette.overdub(ctx::RecordingCtx, ::typeof(Flux.applychain), layers, x)
    for l in layers
        x = Cassette.overdub(ctx, l, x)
    end
    return x
end

@inline function Cassette.overdub(ctx::ReplayCtx, ::typeof(Flux.applychain), layers, x)
    for l in layers
        x = Cassette.overdub(ctx, l, x)
    end
    return x
end

@inline function Cassette.overdub(ctx::RecordingCtx, m::Dense, x::AbstractArray)
    W, b, σ = m.W, m.b, m.σ
    T = LinearAlgebra.promote_op(*, eltype(W), eltype(x))
    y1 = mul!(similar(b, T), W, x)
    y2 = broadcast!(similar(b, T), y1, b) do x, y
        σ(x + y)
    end

    AutoPreallocation.record_alloc!(ctx, y1)
    AutoPreallocation.record_alloc!(ctx, y2)
    return y2
end

@inline function Cassette.overdub(ctx::ReplayCtx, m::Dense, x::AbstractArray)
    W, b, σ = m.W, m.b, m.σ
    y1 = AutoPreallocation.next_scheduled_alloc!(ctx)
    y2 = AutoPreallocation.next_scheduled_alloc!(ctx)

    mul!(y1, W, x)
    broadcast!(y2, y1, b) do x, y
        σ(x + y)
    end
    return y2
end