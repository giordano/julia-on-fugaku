include(joinpath(@__DIR__, "common.jl"))

function axpy!(a, x, y)
    @simd for i in eachindex(x, y)
        @inbounds y[i] = muladd(a, x[i], y[i])
   end
   return y
end

for T in (Float16, Float32, Float64)
    benchmark(axpy!, T, "julia")
end
