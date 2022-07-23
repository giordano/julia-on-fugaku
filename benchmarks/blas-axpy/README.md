# BLAS `axpy` benchmarks

This directory contains the code to run benchmarks of different implementations of the Level
1 BLAS routine `axpy`.

## Run the benchmarks

To run the benchmarks for the different implementations you can use the `*.sh` submissions
scripts.  On a login node:

```
pjsub armpl.sh # for ARM Performance Libraries
pjsub blis.sh # for BLIS
pjsub fujitsu.sh # for Fujitsu BLAS
pjsub julia.sh # for a pure Julia implementation
pjsub openblas.sh # for OpenBLAS
```

Instead, if you are already on a compute node you can run these scripts directly:

```
./armpl.sh
./blis.sh
./fujitsu.sh
./julia.sh
./openblas.sh
```

Note that 

* `armpl.sh` requires you having manually obtained the [ARM Performance
  Libraries](https://developer.arm.com/downloads/-/arm-performance-libraries).  You will
  also have to adjust the path where the module is installed.
* `openblas.sh` requires you to have [Spack](https://spack.io/) v0.19.  You will need to
  adjust the path where you installed Spack.  Note that Fugaku offers a system-wide instance
  of Spack, but this is version v0.11.  This instance also provides OpenBLAS 0.3.18 built
  with the Fujitsu compiler, but this doesn't use the ILP64 interface, needed by Julia.

## Plotting the results

Once you have obtained the results of all benchmarks, you can plot them with

```
julia --project=. plot.jl
```

PDF files `axpy-half.pdf`, `axpy-single.pdf`, and `axpy-double.pdf` will be generated.
