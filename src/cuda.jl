
@inline function Cassette.overdub(
    ctx::RecordingCtx, ::Type{A}, ::UndefInitializer, dims...
) where {A<:CUDA.CuArray}
    ret = A(undef, dims...)
    record_alloc!(ctx, ret)
    return ret
end

@inline function Cassette.overdub(
    ctx::ReplayCtx, ::Type{A}, ::UndefInitializer, dims...
)::A where {A<:CUDA.CuArray}
    scheduled = next_scheduled_alloc!(ctx) :: A
    return scheduled
end
