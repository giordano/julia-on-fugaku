#!/bin/bash
#PJM -L "node=2"                  # Number of node
#PJM -L "rscgrp=small"            # Specify resource group
#PJM -L "elapse=1:00:00"          # Job run time limit value
#PJM --mpi "max-proc-per-node=1"  # Upper limit of number of MPI process created at 1 node
#PJM -S                           # Direction of statistic information file output

# Directory for log of `llio_transfer` and its wrapper `dir_transfer`
LOGDIR="${TMPDIR}/log"

# Create the log directory if necessary
mkdir -p "${LOGDIR}"

# Get directory where Julia is placed
JL_BUNDLE="$(dirname $(julia --startup-file=no -O0 --compile=min -e 'print(Sys.BINDIR)'))"

# Move Julia installation to fast LLIO directory
/home/system/tool/dir_transfer -l "${LOGDIR}" "${JL_BUNDLE}"

# Do not write empty stdout/stderr files for MPI processes.
export PLE_MPI_STD_EMPTYFILE=off

mpiexecjl --project=. -np 2 julia point-to-point-benchmarks.jl

# Remove Julia installation directory from the cache.
/home/system/tool/dir_transfer -p -l "${LOGDIR}" "${JL_BUNDLE}"
