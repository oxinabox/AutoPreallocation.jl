# Developer Notes

Although, the mechanism is simple, the fragile type inference of Julia compiler bring this package to a lot more complicated
performance optimization issue.

## Fixing Type Inference Failures
The best way to find type inference failure and fix it is using [Cthulhu.jl](https://github.com/JuliaDebug/Cthulhu.jl). Once you find a type inference failure, you will need to put them into the Cassette `overdub` pass, e.g

If we find type inference fails for `Base.iterate`, the following function should be defined

```julia
@inline Cassette.overdub(ctx::RecordingCtx, ::typeof(Base.iterate), it, st) = iterate(it, st)
@inline Cassette.overdub(ctx::ReplayCtx, f::typeof(Base.iterate), it, st) = iterate(it, st)
```

where [`RecordingCtx`](@ref) is the Cassette context for the first tracing execution, and the [`ReplayCtx`](@ref) is the actual
runtime Cassette context. You could also read [`inference_fixes.jl`]() for more details.

### Working with Zygote
To work with Zygote, since Zygote will use [IRTools](https://github.com/MikeInnes/IRTools.jl) to implement contextual dispatch,
the type inference failure may be different. However, one should always remember to pass the most type inference failure function to the following functions as well

```julia
@inline Cassette.overdub(ctx::RecordingCtx, ::typeof(Zygote._pullback), cx::Zygote.AContext, ::typeof(Base.iterate), it, st) = Zygote._pullback(cx, Base.iterate, it, st)
@inline Cassette.overdub(ctx::ReplayCtx, ::typeof(Zygote._pullback), cx::Zygote.AContext, ::typeof(Base.iterate), it, st) = Zygote._pullback(cx, Base.iterate, it, st)
```

## Performance Tips

### Transform operations like `pop!`, `push!`

In many cases, one can write `pop!`, or `push!` as a locally preallocated but uninitialized version, e.g

if we the total length of the list is known, we could preallocate the memory in advance, instead of writing

```julia
list = []
for k in 1:L
    x = #= some computation =#
    push!(list, x)
end
```

we could write

```julia
list = Vector{Any}(undef, L)
for k in 1:L
    x = #= some computation =#
    list[k] = x
end
```

then we won't be resizing the `Vector` during runtime, which make it much easier to preallocate everything in the record created
by `AutoPreallocation`.
