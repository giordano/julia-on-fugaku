#!/bin/bash
#PJM -L "node=1"                  # Number of node
#PJM -L "rscgrp=small"            # Specify resource group
#PJM -L "elapse=59:59"            # Job run time limit value
#PJM --mpi "max-proc-per-node=1"  # Upper limit of number of MPI process created at 1 node
#PJM -S                           # Direction of statistic information file output

# execute job
julia --project=. --threads=48 bench.jl
