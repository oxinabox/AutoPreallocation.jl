#########################################################################
using AutoPreallocation, BenchmarkTools

foo() = ones(1, 2096) * ones(2096, 1024) * ones(1024,1)
@btime foo()

const foo_res, foo_record = record_allocations(foo)

@btime avoid_allocations($foo_record, foo)

#########################################################################

using Test
twos(dims) = 2*ones(dims)

const twos_res, twos_record = record_allocations(twos, (3,6))
@test_throws TypeError avoid_allocations(twos_record, twos, (3,6,9))

# If the type is the same and only size differs AutoPreallocation right now won't even
# error, it will just silently return the wrong result
avoid_allocations(twos_record, twos, (30,60))

###############################################################################

function bar(x)
    ys = fill(10.0, 30)
    for ii in 1:100
        push!(ys, x)
    end
    return ys
end

@btime bar(3.14);

const _, bar_record = record_allocations(bar, 3.14);
reinitialize!(bar_record);
@btime avoid_allocations($bar_record, bar, 42.0);

reinitialize!(bar_record);
@btime avoid_allocations($bar_record, bar, 24601);

############################################

function mat(x)
    out = zeros(2,2)
    out[1, 1] = x
    out[2, 2] = x
    return out
end

const mat1, mat_record = record_allocations(mat, 1);
(mat1,)

mat2 = avoid_allocations(mat_record, mat, 2);
(mat1, mat2)  # Notice mat1 has changed

mat3 = avoid_allocations(mat_record, mat, 3);
(mat1, mat2, mat3)  # Notice: mat1 and mat2 have changed
