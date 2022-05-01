include(joinpath(@__DIR__, "common.jl"))

using LinearAlgebra
using BLISBLAS

# Make sure we're using Blis.  NOTE: BLISBLAS doesn't clear OpenBLAS, so there is still a
# chance we're using OpenBLAS (but it should be so slow that you'd notice)
let
    blases = BLAS.get_config().loaded_libs
    blisblas = findfirst(x -> contains(x.libname, r"libblis.so$"), blases)
    @assert !isnothing(blisblas)
    @assert blases[blisblas].interface === :ilp64
end

for T in (Float16, Float32, Float64)
    benchmark(BLAS.axpy!, T, "blis")
end
