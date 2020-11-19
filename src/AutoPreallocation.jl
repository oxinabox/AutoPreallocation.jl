module AutoPreallocation
using Cassette
using LinearAlgebra: LinearAlgebra
using Requires

export avoid_allocations, record_allocations, freeze, preallocate, reinitialize!, @no_prealloc

include("record_types.jl")
include("recording.jl")
include("replaying.jl")
include("inference_fixes.jl")
include("no_prealloc.jl")
include("preallocate.jl")
@init @require CUDA="052768ef-5323-5732-b1bb-66c8b64840ba" include("cuda.jl")

end # module
