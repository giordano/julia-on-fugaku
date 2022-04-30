using MPI

MPI.Init()

const comm = MPI.COMM_WORLD
const rank = MPI.Comm_rank(comm)

function pingpong(T, bufsize, iters)
    buffer = zeros(T, bufsize)
    tag = 0
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    for i = 1:iters
        if rank == 0
            MPI.Send(buffer, 1, tag, comm)
            MPI.Recv!(buffer, 1, tag, comm)
        elseif rank == 1
            MPI.Recv!(buffer, 0, tag, comm)
            MPI.Send(buffer, 0, tag, comm)
        end
    end
    toc = MPI.Wtime()
    avgtime = (toc - tic) / iters
    return avgtime
end

function benchmark()
    T = UInt8

    # Warmup
    pingpong(T, 1, 10)

    if rank == 0
        file = open(joinpath(@__DIR__, "julia.csv"), "w")
        println(file, "# size (bytes),time (seconds),throughput (MB/s)")
    end

    for s in [-Inf, (0:1:27)...]
        size = Int(exp2(s))
        time = pingpong(T, size, 400)
        if rank == 0
            bytes = size * sizeof(T)
            # Riken benchmarks seem to use decimal Megabytes, not binary Mibibytes
            throughput = bytes / 1e6 / time
            @show bytes, time, throughput
            println(file, bytes, ",", time, ",", throughput)
        end
    end

    if rank == 0
        close(file)
    end
end

benchmark()
