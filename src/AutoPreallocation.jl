module AutoPreallocation
using Cassette

export avoid_alloctions, record_alloctions, freeze, reinitialize!

include("record_types.jl")
include("recording.jl")
include("replaying.jl")

end # module
