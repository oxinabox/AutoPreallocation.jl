module AutoPreallocation
using Cassette

export avoid_allocations, record_allocations, freeze, reinitialize!

include("record_types.jl")
include("recording.jl")
include("replaying.jl")

end # module
