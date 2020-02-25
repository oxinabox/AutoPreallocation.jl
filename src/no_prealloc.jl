"""
    @no_prealloc(expr)

Anything inside a `@no_prealloc` will be ignored by AutoPreallocation.jl.
This applies recursively to functions called by functions called etc within the
`@no_prealloc`.
If it allocates then that allocation will always occur -- it won't be avoided by
auto-preallocation.

This can be used if there is a part of a function that may allocation a unknowable
number of intermediary variables to get to the final answer -- and which thus is not
suitable for use with AutoPreallocation.
"""
macro no_prealloc(expr)
    return :(no_prealloc(()->$(esc(expr))))
end

@inline no_prealloc(f) = f()

# Prevent Cassette from recursing into body of f
@inline Cassette.overdub(ctx::RecordingCtx, ::typeof(no_prealloc), f) = f()
@inline Cassette.overdub(ctx::ReplayCtx, ::typeof(no_prealloc), f) = f()
