module AutoPreallocation
using Cassette
using LinearAlgebra: LinearAlgebra

export avoid_allocations, record_allocations, freeze, preallocate, reinitialize!, @no_prealloc

include("record_types.jl")
include("recording.jl")
include("replaying.jl")
include("inference_fixes.jl")
include("no_prealloc.jl")
include("preallocate.jl")

end # module
