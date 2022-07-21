using Statistics, BenchmarkTools, DelimitedFiles

function get_stats(axpy!, N::Int, T::Type)
    b = @benchmark $(axpy!)(a, x, y) setup=(a=randn($T); x=randn($T, $N); y=randn($T, $N)) evals=1
    GC.gc(true)
    N, minimum(b.times), median(b.times), mean(b.times), maximum(b.times)
end

function benchmark(axpy!, T::Type, file_prefix::String)
    open(joinpath(@__DIR__, "$(file_prefix)_$(T).csv"), "w") do file
        println(file, "# length, minimum time (nanoseconds), median time (nanoseconds), mean time (nanoseconds), maximum time (nanoseconds)")
        for N in round.(Int, exp10.(0:0.2:9))
            res = get_stats(axpy!, N, T)
            @show res
            println(file, join(res, ','))
        end
    end
end
