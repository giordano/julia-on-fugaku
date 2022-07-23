# MPI point-to-point operations benchmarks

This directory contains the code to run benchmarks of some MPI point-to-point operations
with `MPI.jl`.

## Run the benchmarks

To run the benchmarks for the different implementations you can use the `job.sh` submission
script.  On a login node run the command:

```
pjsub job.sh
```

## Plotting the results

Once you have obtained the results of all benchmarks, you can plot them with

```
julia --project=. plot.jl
```
