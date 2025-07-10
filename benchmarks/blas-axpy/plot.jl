using Plots, DelimitedFiles

julia_16 = readdlm(joinpath(@__DIR__, "julia_Float16.csv"), ',', Float64; skipstart=1)
julia_32 = readdlm(joinpath(@__DIR__, "julia_Float32.csv"), ',', Float64; skipstart=1)
fujitsu_32 = readdlm(joinpath(@__DIR__, "fujitsu_Float32.csv"), ',', Float64; skipstart=1)
blis_32 = readdlm(joinpath(@__DIR__, "blis_Float32.csv"), ',', Float64; skipstart=1)
armpl_32 = readdlm(joinpath(@__DIR__, "armpl_Float32.csv"), ',', Float64; skipstart=1)
openblas_32 = readdlm(joinpath(@__DIR__, "openblas_Float32.csv"), ',', Float64; skipstart=1)
julia_64 = readdlm(joinpath(@__DIR__, "julia_Float64.csv"), ',', Float64; skipstart=1)
fujitsu_64 = readdlm(joinpath(@__DIR__, "fujitsu_Float64.csv"), ',', Float64; skipstart=1)
blis_64 = readdlm(joinpath(@__DIR__, "blis_Float64.csv"), ',', Float64; skipstart=1)
armpl_64 = readdlm(joinpath(@__DIR__, "armpl_Float64.csv"), ',', Float64; skipstart=1)
openblas_64 = readdlm(joinpath(@__DIR__, "openblas_Float64.csv"), ',', Float64; skipstart=1)

gflops(n, t) = 2 * n / t

# https://www.fujitsu.com/downloads/JP/jsuper/a64fx/a64fx_datasheet.pdf
l1_size =  64 << 10 #  64 KiB
l2_size =  32 << 20 #  32 MiB
linewidth = 2

function plot_benchmarks(title, julia; type::Union{Nothing,DataType}=nothing)
    p = plot(; title=title, xscale=:log10, xlabel="Vector size", ylabel="GFLOPS",
             xticks=floor.(Int, exp10.(0:9)), yticks=0:2.5:40, legend=:topleft)
    if !isnothing(type)
        # Lines corresponding to cache sizes.  Remember that there are two
        # vectors involved, hence the factor `2` at the denominator.
        caches = [l1_size, l2_size] ./ (2 * sizeof(type))
        vline!(p, caches; label="")
        format(str) = (str, 8, :black, :left)
        annotate!(p, caches[1] * 1.2, 1, format("L1"))
        annotate!(p, caches[2] * 1.2, 1, format("L2"))
    end
    plot!(p, julia[:, 1], gflops.(julia[:, 1], julia[:, 2]); label="Julia", marker=:auto, markersize=3)
    return p
end

function plot_benchmarks_no_armpl(title, julia, fujitsu, blis, openblas; type::Union{Nothing,DataType}=nothing)
    p = plot_benchmarks(title, julia; type)
    plot!(p, fujitsu[:, 1], gflops.(fujitsu[:, 1], fujitsu[:, 2]); label="Fujitsu BLAS", marker=:auto, markersize=3)
    plot!(p, blis[:, 1], gflops.(blis[:, 1], blis[:, 2]); label="BLIS", marker=:auto, markersize=3)
    plot!(p, openblas[:, 1], gflops.(openblas[:, 1], openblas[:, 2]); label="OpenBLAS", marker=:auto, markersize=3)
    return p
end

function plot_benchmarks(title, julia, fujitsu, blis, openblas, armpl; type::Union{Nothing,DataType}=nothing)
    p = plot_benchmarks_no_armpl(title, julia, fujitsu, blis, openblas; type)
    plot!(p, armpl[:, 1], gflops.(armpl[:, 1], armpl[:, 2]); label="ARMPL", marker=:auto, markersize=3)
    return p
end

plot_benchmarks("axpy (half precision)", julia_16; type=Float16)
savefig("axpy-half.pdf")
plot_benchmarks("axpy (single precision)", julia_32, fujitsu_32, blis_32, openblas_32, armpl_32; type=Float32)
savefig("axpy-single.pdf")
plot_benchmarks("axpy (double precision)", julia_64, fujitsu_64, blis_64, openblas_64, armpl_64; type=Float64)
savefig("axpy-double.pdf")
# plot_benchmarks_no_armpl("axpy (single precision)", julia_32, fujitsu_32, blis_32)
# savefig("axpy-single-no-armpl.pdf")
# plot_benchmarks_no_armpl("axpy (double precision)", julia_64, fujitsu_64, blis_64)
# savefig("axpy-double-no-armpl.pdf")
