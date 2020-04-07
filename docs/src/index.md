# AutoPreallocation.jl

Have you ever wanted your code to allocate less? Have you ever felt explictly preallocating everything was just too hard? Have you ever thought: "why not just reuse the allocated memory from last time"? Well look no further, friend.

## How to use

The simplest way of using this package is via only one function [`preallocate`](@ref), e.g

```@repl
using AutoPreallocation, BenchmarkTools
foo() = ones(1, 2096) * ones(2096, 1024) * ones(1024,1)
@btime foo()
x, preallocated_foo = preallocate(foo)
@btime preallocated_foo()
```

## Limitations

Despite the hip introduction, AutoPreallocation is not a tool to use lightly. It requires you understand the following limitations, which while relatively rare in practice certainly do occur.

AutoPreallocation is also not hugely mature (yet), and if you violate these limitations, it may silently give you the wrong answer.

### Function must always allocate the same way. (per record object)
You cannot reuse the same record of allocations across calls to the function with different allocation patterns. Every call that uses a given record, must allocate Arrays of the same type and size, in the same order.

Failure to do so may give errors, or silently incorrect results (#1)

For example:

```@repl
using Test, AutoPreallocation
twos(dims) = 2*ones(dims)
twos_res, twos_record = record_allocations(twos, (3,6))
@test_throws TypeError avoid_allocations(twos_record, twos, (3,6,9))

# If the type is the same and only size differs AutoPreallocation right now won't even
# error, it will just silently return the wrong result
avoid_allocations(twos_record, twos, (30,60))
```

One way to deal with this is to keep track of which parameters change the allocation pattern, and then declare one record for each of them.

If one part of your function has nondetermanistic internal allocations you can mark that section to be ignored by wrapping it in [`@no_prealloc`](@ref).

### If a function resizes any array that it allocates you need to call reinitialize!
The allocated memory is reuses. Which means if you call an operation like `push!` or `append!` that resizes it, then it will be resized the next time it goes to be used. reinitialize!(record) resets the memory to its initial state.

If you are not sure if internally this ever happens then to be safe just call `reinitialize!` everytime before using the record.

```@repl
using AutoPreallocation, BenchmarkTools

function bar(x)
    ys = fill(10.0, 30)
    for ii in 1:100
        push!(ys, x)
    end
    return ys
end

@btime bar(3.14);
const _, bar_record = record_allocations(bar, 3.14);
reinitialize!(bar_record);  # Even the first time after recording
@btime avoid_allocations($bar_record, bar, 42.0);
reinitialize!(bar_record);
@btime avoid_allocations($bar_record, bar, 24601);
```

### If you are storing output which was allocated within the function, you need to take a `copy`
Due to the memory being reused if the record is used in another function call the output will be over-written.
You should take a `copy` (don't need a `deepcopy`, plain `copy` is fine), to avoid this.

Here is an example of what happens if you don't:
```@repl
using AutoPreallocation
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
```

## API Reference

```@autodocs
Modules = [AutoPreallocation]
```
