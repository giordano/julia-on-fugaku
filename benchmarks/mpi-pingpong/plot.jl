using Plots, DelimitedFiles

function plot_bench()
    julia = readdlm(joinpath(@__DIR__, "julia.csv"), ',', Float64; skipstart=1)
    riken = readdlm(joinpath(@__DIR__, "riken.csv"), ',', Float64; skipstart=1)

    p = plot(;
             title = "Communication time of MPI PingPong",
             xlabel = "message size [bytes]",
             xscale = :log10,
             xlims = (1, Inf),
             xticks = floor.(Int, exp10.(0:9)),
             ylabel = "time [sec]",
             yscale = :log10,
             legend=:topleft,
             )
    plot!(p, julia[:, 1], julia[:, 2]; label="MPI.jl", marker=:auto, markersize=3)
    plot!(p, riken[:, 1], riken[:, 2]; label="Riken-CCS", marker=:auto, markersize=3)
    savefig(joinpath(@__DIR__, "ping-pong-time.pdf"))

    p = plot(;
             title = "Throughput of MPI PingPong",
             xlabel = "message size [bytes]",
             xscale = :log10,
             xlims = (1, Inf),
             xticks = floor.(Int, exp10.(0:9)),
             ylabel = "throughput [MB/s]",
             legend=:topleft,
             )
    plot!(p, julia[:, 1], julia[:, 3]; label="MPI.jl", marker=:auto, markersize=3)
    plot!(p, riken[:, 1], riken[:, 3]; label="Riken-CCS", marker=:auto, markersize=3)
    savefig(joinpath(@__DIR__, "ping-pong-throughput.pdf"))

end

plot_bench()
