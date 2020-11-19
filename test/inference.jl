using AutoPreallocation

function inferred_and_nonallocating(f)
    pf = preallocate(f)[2]
    @test (@inferred(pf()); true)
    @test @allocated(pf())==0
end

# the different forms of Array constructors which exist
inferred_and_nonallocating() do
    Array{Float64}(undef, 4, 5)
end
inferred_and_nonallocating() do
    Array{Float64}(undef, (4, 5))
end
inferred_and_nonallocating() do
    Array{Float64,2}(undef, 4, 5)
end
inferred_and_nonallocating() do
    Array{Float64,2}(undef, (4, 5))
end
inferred_and_nonallocating() do
    Array{Float64,2}(undef, (4, 5))
end
inferred_and_nonallocating() do
    Array{Float64,3}(undef, (4, 5, 6))
end

# slightly deeper
inferred_and_nonallocating() do 
    zeros(Float64,3)
end

# two different typed arrays in the record
inferred_and_nonallocating() do 
    zeros(Float32,3)
    zeros(Float64,3)
end

# some more complex broadcasting and temporary arrays
inferred_and_nonallocating() do 
    x = zeros(Float32,3)
    y = zeros(Float64,3)
    z = 2 .* x .+ y
    3 .+ z
end