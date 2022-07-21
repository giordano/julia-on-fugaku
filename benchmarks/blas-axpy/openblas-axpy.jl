include(joinpath(@__DIR__, "common.jl"))

using LinearAlgebra

# Load OpenBLAS built with Spack
const openblas_path = "spack-env/.spack-env/view/lib/libopenblas64_.so"
BLAS.lbt_forward(openblas_path; clear=true)

# Make sure we're using the right OpenBLAS
let
    blases = BLAS.get_config().loaded_libs
    openblas = findfirst(x -> contains(x.libname, openblas_path), blases)
    @assert isone(BLAS.get_num_threads())
    @assert !isnothing(openblas)
    @assert blases[openblas].interface === :ilp64
end

for T in (Float16, Float32, Float64)
    benchmark(BLAS.axpy!, T, "openblas")
end
