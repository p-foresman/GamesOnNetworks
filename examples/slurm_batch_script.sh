#!/bin/bash
#SBATCH --job-name=GamesOnNetworks_RG    # create a short name for your job
#SBATCH --partition medium
#SBATCH --output=slurm-%A.%a.out # stdout file
#SBATCH --error=slurm-%A.%a.err  # stderr file
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=20        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --array=1-240              # job array with index values 1-240
#SBATCH --mail-type=all          # send email on job start, end and fault
#SBATCH --mail-user=fores2@pdx.edu

echo "My SLURM_ARRAY_JOB_ID is $SLURM_ARRAY_JOB_ID."
echo "My SLURM_ARRAY_TASK_ID is $SLURM_ARRAY_TASK_ID"
echo "Executing on the machine:" $(hostname)

julia ./slurm_simulations.jl