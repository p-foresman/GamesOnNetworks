#!/bin/bash
#SBATCH --job-name=GamesOnNetworks_RG_e2    # create a short name for your job
#SBATCH --partition long
#SBATCH --output=slurm__e0.2__-%A.%a.out # stdout file
#SBATCH --error=slurm__e0.2__-%A.%a.err  # stderr file
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=20        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mail-type=all          # send email on job start, end and fault
#SBATCH --mail-user=fores2@pdx.edu


echo "Executing on the machine:" $(hostname)

julia ./slurm_simulations_iteration.jl