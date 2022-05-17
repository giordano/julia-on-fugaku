using MPIBenchmarks

# Alltoall is very slow, we need to do fewer iterations
function alltoall_iterations(::Type{T}, s::Int) where {T}
    log2size = trailing_zeros(sizeof(T))
    return 1 << ((s < 10 - log2size) ? (16 - log2size) : (26 - 2 * log2size - s))
end

# Collective benchmarks
benchmark(IMBAllreduce())
benchmark(IMBAlltoall(; max_size=2 ^ 20, iterations=alltoall_iterations))
benchmark(IMBGatherv(; max_size=2 ^ 20, iterations=alltoall_iterations))
# benchmark(IMBReduce())
benchmark(OSUAllreduce())
benchmark(OSUAlltoall(; max_size=2 ^ 20, iterations=alltoall_iterations))
# benchmark(OSUReduce())
