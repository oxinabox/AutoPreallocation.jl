module AutoPreallocation
using Cassette

export avoid_alloctions, record_alloctions

include("record.jl")
include("replay.jl")

end # module
