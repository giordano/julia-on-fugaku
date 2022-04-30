include(joinpath(@__DIR__, "common.jl"))

using LinearAlgebra
using FujitsuBLAS

# Make sure we're using Fujitsu BLAS
let
    blases = BLAS.get_config().loaded_libs
    fjblas = findfirst(x -> contains(x.libname, r"libfjlapackexsve_ilp64.so$"), blases)
    @assert !isnothing(fjblas)
    @assert blases[fjblas].interface === :ilp64
end

for T in (Float16, Float32, Float64)
    benchmark(BLAS.axpy!, T, "fujitsu")
end
