using CSV
using DataFrames
using Plots

bwscaling = CSV.read(joinpath(@__DIR__, "bwscaling.csv"), DataFrame)
flopsscaling = CSV.read(joinpath(@__DIR__, "flopsscaling.csv"), DataFrame)
latencies = CSV.read(joinpath(@__DIR__, "latencies.csv"), DataFrame)

function plot_scaling(df, title, ylabel)
    plot(df[:, 1], df[:, 2];
         title,
         xlabel="# Threads",
         xticks=0:4:48,
         ylabel,
         marker=:circle,
         markersize=3,
         label="",
         size=(800, 600),
         )
end

plot_scaling(bwscaling, "Memory Bandwidth Scaling", "SDaxpy Bandwidth (MB/s)")
savefig(joinpath(@__DIR__, "bwscaling.pdf"))
plot_scaling(flopsscaling, "FLOPS Scaling", "Triad Performance (MFlop/s)")
savefig(joinpath(@__DIR__, "flopsscaling.pdf"))
heatmap(Matrix(latencies); c=:viridis, frame=:box)
savefig(joinpath(@__DIR__, "latencies.pdf"))
