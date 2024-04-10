#!/bin/bash
#SBATCH --job-name=GamesOnNetworks_COMPLETE    # create a short name for your job
#SBATCH --partition long
#SBATCH --output=complete-%A.%a.out # stdout file
#SBATCH --error=complete-%A.%a.err  # stderr file
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=20        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --array=1-70              # job array with index values 1-70
#SBATCH --mail-type=all          # send email on job start, end and fault
#SBATCH --mail-user=fores2@pdx.edu

echo "My SLURM_ARRAY_JOB_ID is $SLURM_ARRAY_JOB_ID."
echo "My SLURM_ARRAY_TASK_ID is $SLURM_ARRAY_TASK_ID"
echo "Executing on the machine:" $(hostname)

julia ./slurm_simulations_AEY.jl