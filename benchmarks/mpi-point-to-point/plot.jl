using Plots, DelimitedFiles

# Convert decimal Megabyte to binary Gibibyte
mb_to_gib(x) = x * (1e6 / (2 ^ 30))

function plot_ping(name::String)
    system = "Fugaku"
    xlims = (1, 2 ^ 23)
    xticks = (exp2.(0:2:22), ["1 B",   "4 B",   "16 B",   "64 B",   "256 B",
                              "1 KiB", "4 KiB", "16 KiB", "64 KiB", "256 KiB",
                              "1 MiB", "4 MiB"])

    julia = readdlm(joinpath(@__DIR__, "julia_imb_$(lowercase(name)).csv"), ',', Float64; skipstart=1)
    riken = readdlm(joinpath(@__DIR__, "riken_imb_$(lowercase(name)).csv"), ',', Float64; skipstart=1)

    p = plot(;
             title = "Latency of MPI $(name) @ $(system)",
             xlabel = "message size",
             xscale = :log10,
             xlims,
             xticks,
             ylabel = "time [sec]",
             yscale = :log10,
             legend=:topleft,
             )
    plot!(p, julia[:, 1], julia[:, 3]; label="Julia (MPI.jl)", marker=:auto, markersize=3)
    plot!(p, riken[:, 1], riken[:, 2]; label="C (Riken-CCS)", marker=:auto, markersize=3)
    savefig(joinpath(@__DIR__, "$(lowercase(name))-latency.pdf"))

    p = plot(;
             title = "Throughput of MPI $(name) @ $(system)",
             xlabel = "message size",
             xscale = :log10,
             xlims,
             xticks,
             ylabel = "throughput [GiB/s]",
             legend=:topleft,
             )
    plot!(p, julia[:, 1], mb_to_gib.(julia[:, 4]); label="Julia (MPI.jl)", marker=:auto, markersize=3)
    plot!(p, riken[:, 1], mb_to_gib.(riken[:, 3]); label="C (Riken-CCS)", marker=:auto, markersize=3)
    savefig(joinpath(@__DIR__, "$(lowercase(name))-throughput.pdf"))

end

plot_ping("PingPong")
plot_ping("PingPing")
