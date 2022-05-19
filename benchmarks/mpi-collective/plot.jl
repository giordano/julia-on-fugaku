using Plots, DelimitedFiles

function plot_bench(name::String; xlims=(1, 2 ^ 23))
    system = "Fugaku"
    xticks = (exp2.(0:2:22), ["1 B",   "4 B",   "16 B",   "64 B",   "256 B",
                              "1 KiB", "4 KiB", "16 KiB", "64 KiB", "256 KiB",
                              "1 MiB", "4 MiB"])

    julia = readdlm(joinpath(@__DIR__, "julia_imb_$(lowercase(name)).csv"), ',', Float64; skipstart=1)
    riken = readdlm(joinpath(@__DIR__, "riken_imb_$(lowercase(name)).csv"), ',', Float64; skipstart=1)

    p = plot(;
             title = "Latency of MPI $(name) @ $(system) (384 nodes, 1536 ranks)",
             titlefont=font(12),
             xlabel = "message size",
             xscale = :log10,
             xlims,
             xticks,
             ylabel = "time [sec]",
             yscale = :log10,
             legend=:topleft,
             )
    # For MPI.jl plot average time.  I don't know what time is used in Riken results
    plot!(p, julia[:, 1], julia[:, 5]; label="Julia (MPI.jl)", marker=:auto, markersize=3)
    plot!(p, riken[:, 1], riken[:, 2]; label="C (Riken-CCS)", marker=:auto, markersize=3)
    savefig(joinpath(@__DIR__, "$(lowercase(name))-latency.pdf"))

end

plot_bench("Allreduce")
plot_bench("Gatherv"; xlims=(1, 2 ^ 20.5))
