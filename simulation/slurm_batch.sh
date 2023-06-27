#!/bin/bash
#SBATCH --job-name=GamesOnNetworksBehavioral     # create a short name for your job
#SBATCH --partition long
#SBATCH --output=slurm-%A.%a.out # stdout file
#SBATCH --error=slurm-%A.%a.err  # stderr file
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=20        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --array=1-24              # job array with index values 1-24
#SBATCH --mail-type=all          # send email on job start, end and fault
#SBATCH --mail-user=fores2@pdx.edu

echo "My SLURM_ARRAY_JOB_ID is $SLURM_ARRAY_JOB_ID."
echo "My SLURM_ARRAY_TASK_ID is $SLURM_ARRAY_TASK_ID"
echo "Executing on the machine:" $(hostname)

julia ./run_simulation_slurm.jl