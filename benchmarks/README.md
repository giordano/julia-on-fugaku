# Julia benchmarks on Fugaku

In the subdirectories of this folder is the code to run some benchmarks of Julia on Fugaku.
We used Julia v1.7.2, and we strongly recommend using the same version for reproducible
results:

- other versions may yield different results for Julia-specific benchmarks
- the Pkg environments provided are specific to the v1.7 series of Julia.  Trying to
  instantiate them with different versions of Julia _may_ result in resolution errors
  (especially if using older versions of Julia), or in different versions of some packages
  being installed because of external constraints, thus not being able to faithfully
  reproduce the same environment.

In all cases you need to have the `julia` executable available in the `PATH` environment
variable.  One way to do it is to obtain the program from the [official Julia downloads
webpage](https://julialang.org/downloads/) (64-bit ARM Linux), unpack the tarball, and add
the directory where the `julia` executable is to the `PATH` environment variable.

For the MPI benchmarks, we used `MPI.jl` v0.20, which is the first series to natively
support Fujitsu MPI out-of-the-box (previous versions will require manual intervention to
configure it correctly).  Note that as of this writing (July 2022), this version is still in
development.  You will also need to install the [Julia wrapper for
`mpiexec`](https://juliaparallel.org/MPI.jl/dev/usage/#Julia-wrapper-for-mpiexec) and make
it available in the `PATH` environment variable.
