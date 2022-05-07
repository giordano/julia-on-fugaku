using MPI

MPI.Init()

const comm = MPI.COMM_WORLD
const rank = MPI.Comm_rank(comm)

function mpi_reduce(T, bufsize, iters)
    send_buffer = zeros(T, bufsize)
    recv_buffer = zeros(T, bufsize)
    MPI.Barrier(comm)
    tic = MPI.Wtime()
    for i = 1:iters
        MPI.Reduce!(send_buffer, recv_buffer, +, comm)
    end
    toc = MPI.Wtime()
    avgtime = (toc - tic) / iters
    return avgtime
end

function benchmark()
    T = UInt8

    # Warmup
    mpi_reduce(T, 1, 10)

    if iszero(rank)
        file = open(joinpath(@__DIR__, "julia.csv"), "w")
        println(file, "size (bytes),min_time (seconds),max_time (seconds),avg_time (seconds)")
    end

    for s in -1:22
        size = 1 << s
        iters = s < 16 ? 1000 : (640 >> (s - 16))
        # Measure time on current rank
        time = mpi_reduce(T, size, iters)

        if !iszero(rank)
            # If we are on rank 1, send to rank 0 our time
            MPI.Send(time, comm; dest=0)
        else
            # Number of ranks
            nranks = MPI.Comm_size(comm)
            # Vector of timings across all ranks
            times = zeros(nranks)
            # Set first element of the vector to the time on rank 0
            times[1] = time

            # Collect all the times from all other ranks
            for source in 1:(nranks - 1)
                times[source + 1] = MPI.Recv(typeof(time), comm; source)
            end

            # Minimum time measured across all ranks
            min_time = minimum(times)
            # Maximum time measured across all ranks
            max_time = maximum(times)
            # Average time measured across all ranks
            avg_time = sum(times) / length(times)

            # Number of bytes trasmitted
            bytes = size * sizeof(T)

            # Print out our results
            @show bytes, min_time, max_time, avg_time
            println(file, bytes, ",", min_time, ",", max_time, ",", avg_time)
        end
    end

    if iszero(rank)
        close(file)
    end
end

benchmark()
