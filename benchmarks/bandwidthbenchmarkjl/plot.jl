using CSV
using DataFrames
using Plots

bwscaling = CSV.read(joinpath(@__DIR__, "bwscaling.csv"), DataFrame)
flopsscaling = CSV.read(joinpath(@__DIR__, "flopsscaling.csv"), DataFrame)
latencies = CSV.read(joinpath(@__DIR__, "latencies.csv"), DataFrame)

function plot_scaling(df, title, ylabel, column)
    plot(df[:, 1], df[:, column] ./ 1000;
         title,
         xlabel="# Threads",
         xticks=0:4:48,
         ylabel,
         marker=:circle,
         markersize=3,
         label="",
         )
end

for (idx, name) in enumerate(("Init", "Copy", "Update", "Triad", "Daxpy", "STriad", "SDaxpy"))
    plot_scaling(bwscaling, "Memory Bandwidth Scaling for $(name)", "Bandwidth (GB/s)", idx+1)
    savefig(joinpath(@__DIR__, "bwscaling-$(lowercase(name)).pdf"))
end
plot_scaling(flopsscaling, "FLOPS Scaling", "Triad Performance (GFlop/s)", 2)
savefig(joinpath(@__DIR__, "flopsscaling.pdf"))
heatmap(Matrix(latencies); c=:viridis, frame=:box)
savefig(joinpath(@__DIR__, "latencies.pdf"))
