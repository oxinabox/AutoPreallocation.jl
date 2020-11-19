using AutoPreallocation, Test

function inferred_and_nonallocating(f)
    pf = preallocate(f)[2]
    @inferred(pf())
    @allocated(pf()) == 0
end

# the different forms of Array constructors which exist
@test inferred_and_nonallocating() do
    Array{Float64}(undef, 4)
end
@test inferred_and_nonallocating() do
    Array{Float64,1}(undef, 4)
end
@test inferred_and_nonallocating() do
    Array{Float64}(undef, 4, 5)
end
@test inferred_and_nonallocating() do
    Array{Float64}(undef, (4, 5))
end
@test inferred_and_nonallocating() do
    Array{Float64,2}(undef, 4, 5)
end
@test inferred_and_nonallocating() do
    Array{Float64,2}(undef, (4, 5))
end
@test inferred_and_nonallocating() do
    Array{Float64,2}(undef, (4, 5))
end
@test inferred_and_nonallocating() do
    Array{Float64,3}(undef, (4, 5, 6))
end

# slightly deeper
@test inferred_and_nonallocating() do 
    zeros(Float64,3)
end

# two different typed arrays in the record
@test inferred_and_nonallocating() do 
    zeros(Float32,3)
    zeros(Float64,3)
end

# some more complex broadcasting and temporary arrays
@test inferred_and_nonallocating() do 
    x = zeros(Float32,3)
    y = zeros(Float64,3)
    z = 2 .* x .+ y
    3 .+ z
end


# issue #24
struct Foo end
Foo() = Vector{Float64}(undef,10)
@test_broken inferred_and_nonallocating(Foo) # dont understand why this isnt inferred
@test inferred_and_nonallocating(()->Foo())