using MPIBenchmarks

function iterations(::Type{T}, s::Int) where {T}
    log2size = trailing_zeros(sizeof(T))
    return 4 << ((s < 10 - log2size) ? (20 - log2size) : (30 - 2 * log2size - s))
end

# Point-to-point benchmarks
benchmark(IMBPingPong(; iterations))
benchmark(IMBPingPing(; iterations))
benchmark(OSULatency(; iterations))
