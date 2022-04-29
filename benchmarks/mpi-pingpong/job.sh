#!/bin/bash
#PJM -L "node=2"                  # Number of node
#PJM -L "rscgrp=small"            # Specify resource group
#PJM -L "elapse=20:00"            # Job run time limit value
#PJM --mpi "max-proc-per-node=1"  # Upper limit of number of MPI process created at 1 node
#PJM -S                           # Direction of statistic information file output

mpiexecjl --project=. -np 2 julia pingpong.jl
