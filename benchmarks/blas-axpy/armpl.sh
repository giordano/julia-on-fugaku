#!/bin/bash
#PJM -L "node=1"                  # Number of node
#PJM -L "rscgrp=small"            # Specify resource group
#PJM -L "elapse=59:59"            # Job run time limit value
#PJM --mpi "max-proc-per-node=1"  # Upper limit of number of MPI process created at 1 node
#PJM -S                           # Direction of statistic information file output

# execute job
export OMP_NUM_THREADS=1

# Load the module of ARM Performance Libraries
module use ${DATADIR}/arm-performance-libraries/modulefiles
module load armpl/22.0.2_gcc-8.2

julia --project=. armpl-axpy.jl
