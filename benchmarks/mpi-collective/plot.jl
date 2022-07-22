using Plots, DelimitedFiles

function format_bytes(bytes)
    log2b = log2(bytes)
    unit, val = divrem(log2b, 10)
    val = Int(exp2(val))
    unit_string = if unit == 0
        " B"
    elseif unit == 1
        " KiB"
    elseif unit == 2
        " MiB"
    elseif unit == 3
        " GiB"
    elseif unit == 4
        " TiB"
    end
    return string(val) * unit_string
end

function plot_bench(name::String; xlims=(1, 2 ^ 23), ylims=(Inf, Inf))
    system = "Fugaku"
    xticks_range = exp2.(log2(first(xlims)):2:log2(last(xlims)))
    xticks = (xticks_range, format_bytes.(xticks_range))

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
             ylims,
             yscale = :log10,
             legend=:topleft,
             )
    # For MPI.jl plot average time.  I don't know what time is used in Riken results
    plot!(p, julia[:, 1], julia[:, 5]; label="Julia (MPI.jl)", marker=:auto, markersize=3)
    plot!(p, riken[:, 1], riken[:, 2]; label="C (Riken-CCS)", marker=:auto, markersize=3)
    savefig(joinpath(@__DIR__, "$(lowercase(name))-latency.pdf"))

end

plot_bench("Allreduce"; xlims=(4, 2 ^ 22.5), ylims=(10 ^ -6, Inf))
plot_bench("Gatherv"; xlims=(1, 2 ^ 20.5))
plot_bench("Reduce"; xlims=(4, 2 ^ 22.5), ylims=(10 ^ -6, Inf))
