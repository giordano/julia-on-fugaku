using BandwidthBenchmark
using DataFrames
using CSV
using ThreadPinning

pinthreads(:scatter; places=:numa)

CSV.write(joinpath(@__DIR__, "bwbench.csv"), bwbench(; verbose=true))
let
    m = bwscaling()
    df = DataFrame("# Threads" => m[:, 1],
                   "Init Bandwidth (MB/s)" => m[:, 2],
                   "Copy Bandwidth (MB/s)" => m[:, 3],
                   "Update Bandwidth (MB/s)" => m[:, 4],
                   "Triad Bandwidth (MB/s)" => m[:, 5],
                   "Daxpy Bandwidth (MB/s)" => m[:, 6],
                   "STriad Bandwidth (MB/s)" => m[:, 7],
                   "SDaxpy Bandwidth (MB/s)" => m[:, 8],
                   )
    CSV.write(joinpath(@__DIR__, "bwscaling.csv"), df)
end
let
    m = flopsscaling()
    df = DataFrame("# Threads" => m[:, 1], "Triad Performance (MFlop/s)" => m[:, 2])
    CSV.write(joinpath(@__DIR__, "flopsscaling.csv"), df)
end
