include(joinpath(@__DIR__, "common.jl"))

using LinearAlgebra
import Libdl: find_library

if "LD_LIBRARY_PATH" in keys(ENV)
    library_path = split(ENV["LD_LIBRARY_PATH"], ':')
    armpl_path = find_library("libarmpl_ilp64_mp.so", library_path)
    @show BLAS.lbt_forward(armpl_path; clear=true)
else
    error("Environment variable `LD_LIBRARY_PATH` not set. Did you load the `armpl` module?")
end

# Make sure we're using Arm Performance Library
let
    blases = BLAS.get_config().loaded_libs
    armpl = findfirst(x -> contains(x.libname, r"libarmpl_ilp64_mp.so$"), blases)
    @assert !isnothing(armpl)
    @assert blases[armpl].interface === :ilp64
end

for T in (Float32, Float64)
    benchmark(BLAS.axpy!, T, "armpl")
end
