#!/bin/bash
#PJM -L "node=1"                  # Number of node
#PJM -L "rscgrp=small"            # Specify resource group
#PJM -L "elapse=2:59:59"          # Job run time limit value
#PJM --mpi "max-proc-per-node=1"  # Upper limit of number of MPI process created at 1 node
#PJM -S                           # Direction of statistic information file output

# execute job
export OMP_NUM_THREADS=1

# Use local installation of Spack, much more recent than the one available in the system.
. ${DATADIR}/repo/spack/share/spack/setup-env.sh
# Install OpenBLAS from local Spack environment
spack -e spack-env install -j 40

julia --project=. openblas-axpy.jl
