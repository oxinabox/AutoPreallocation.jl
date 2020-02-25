module AutoPreallocation
using Cassette

export avoid_allocations, record_allocations, freeze, reinitialize!, @no_prealloc

include("record_types.jl")
include("recording.jl")
include("replaying.jl")
include("no_prealloc.jl")

end # module
