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
        println(file, "size (bytes),time (seconds),throughput (MB/s)")
    end

    for s in -1:22
        size = 1 << s
        iters = 1 << (s < 10 ? 20 : 30 - s)
        # Measure time on current rank
        time = pingpong(T, size, iters)

        if rank == 1
            # If we are on rank 1, send to rank 0 our time
            MPI.Send(time, comm; dest=0)
        else
            # Time on rank 0
            time_0 = time
            # Time on rank 1
            time_1 = MPI.Recv(typeof(time), comm; source=1)
            # Maximum of the times measured across all ranks
            max_time = max(time_0, time_1)
            # Aggregate time across all ranks
            aggregate_time = time_0 + time_1

            # Number of ranks
            nranks = MPI.Comm_size(comm)
            # Number of bytes trasmitted
            bytes = size * sizeof(T)
            # Latency
            latency = aggregate_time / (2 * nranks)
            # Throughput
            throughput = (nranks * bytes) / max_time / 1e6

            # Print out our results
            @show bytes, latency, throughput
            println(file, bytes, ",", latency, ",", throughput)
        end
    end

    if rank == 0
        close(file)
    end
end

benchmark()
