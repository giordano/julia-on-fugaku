using BandwidthBenchmark
using DataFrames
using CSV
using ThreadPinning

pinthreads(:scatter; places=:numa)

CSV.write(joinpath(@__DIR__, "bwbench.csv"), bwbench(; verbose=true))
let
    m = bwscaling()
    df = DataFrame("# Threads" => m[:, 1], "SDaxpy Bandwidth (MB/s)" => m[:, 2])
    CSV.write(joinpath(@__DIR__, "bwscaling.csv"), df)
end
let
    m = flopsscaling()
    df = DataFrame("# Threads" => m[:, 1], "Triad Performance (MFlop/s)" => m[:, 2])
    CSV.write(joinpath(@__DIR__, "flopsscaling.csv"), df)
end
