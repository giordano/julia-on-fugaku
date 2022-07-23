# MPI collective operations benchmarks

This directory contains the code to run benchmarks of some MPI collective operations with
`MPI.jl`.

## Run the benchmarks

To run the benchmarks for the different implementations you can use the `job.sh` submission
script.  On a login node run the command:

```
pjsub job.sh
```

NOTE: this will launch a job on 384 nodes, with layout `4x6x16:torus:strict-io`.  This may
take up to a few days to be started.

## Plotting the results

Once you have obtained the results of all benchmarks, you can plot them with

```
julia --project=. plot.jl
```
