using Plots, DelimitedFiles

function plot_bench()
    system = "Fugaku"
    xlims = (1, 2 ^ 23)
    xticks = (exp2.(0:2:22), ["1 B",   "4 B",   "16 B",   "64 B",   "256 B",
                              "1 KiB", "4 KiB", "16 KiB", "64 KiB", "256 KiB",
                              "1 MiB", "4 MiB"])

    julia = readdlm(joinpath(@__DIR__, "julia.csv"), ',', Float64; skipstart=1)
    riken = readdlm(joinpath(@__DIR__, "riken.csv"), ',', Float64; skipstart=1)

    p = plot(;
             title = "Latency of MPI Allreduce @ $(system) (384 nodes, 1536 ranks)",
             titlefont=font(12),
             xlabel = "message size",
             xscale = :log10,
             xlims,
             xticks,
             ylabel = "time [sec]",
             yscale = :log10,
             legend=:topleft,
             )
    plot!(p, julia[:, 1], julia[:, 2]; label="Julia (MPI.jl)", marker=:auto, markersize=3)
    plot!(p, riken[:, 1], riken[:, 2]; label="C (Riken-CCS)", marker=:auto, markersize=3)
    savefig(joinpath(@__DIR__, "allreduce.pdf"))
end

plot_bench()
