module AutoPreallocation
using Cassette

export avoid_alloctions, record_alloctions, freeze, reinitialize!

include("record.jl")
include("replay.jl")
include("record_utils.jl")
end # module
