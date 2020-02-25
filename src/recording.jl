Cassette.@context RecordingCtx
new_recording_ctx() = Cassette.disablehooks(RecordingCtx(metadata=AllocationRecord()))

function record_alloc!(record::AllocationRecord, val)
    push!(record.initial_sizes, size(val))
    push!(record.allocations, val)
end
record_alloc!(ctx::RecordingCtx, val) = record_alloc!(ctx.metadata, val)


@inline function Cassette.overdub(
    ctx::RecordingCtx, ::Type{Array{T,N}}, ::UndefInitializer, dims
) where {T,N}
    ret = Array{T, N}(undef, dims)
    record_alloc!(ctx, ret)
    return ret
end

function record_allocations(f, args...; kwargs...)
    ctx = new_recording_ctx()
    value = Cassette.overdub(ctx, f, args...; kwargs...)

    return (value=value, allocation_record=ctx.metadata,)
end
