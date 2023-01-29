#!/bin/bash
#SBATCH --job-name games_on_networks
#SBATCH --partition <Select your partition.>
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mail-type=ALL
#SBATCH --mail-user=parker.foresman@gmail.com
#SBATCH --output test_output.txt
#SBATCH --error test_error.err

julia