include(joinpath(@__DIR__, "common.jl"))

using LinearAlgebra

# Make sure we're using the right OpenBLAS
let
    blases = BLAS.get_config().loaded_libs
    # openblas = findfirst(x -> contains(x.libname, r"libopenblas.*\.so"), blases)
    # @assert !isnothing(openblas)
    BLAS.set_num_threads(1)
    @assert isone(BLAS.get_num_threads())
    @assert blases[openblas].interface === :ilp64
end

for T in (Float32, Float64)
    benchmark(BLAS.axpy!, T, "openblas")
end
