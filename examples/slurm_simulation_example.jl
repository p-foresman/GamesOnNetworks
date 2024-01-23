"""
Example file that could be called from a SLURM batch script.
"""

"""
Step 1: Use the "Distributed" package in order to add processes for multiple runs of each simulation model.
    -addprocs() will define the run count (each run will run on a different CPU core).
    -The number supplied to addprocs() must match the "cpus-per-task" variable in the slurm batch file.
    -be aware of the core count and RAM on the machine
"""
using Distributed
addprocs(20; exeflags="--project")

"""
Step 2: Load the main "GamesOnNetworks" module onto all processes
"""
@everywhere using GamesOnNetworks

"""
Step 3: Define a database filepath
    -an sqlite database file should be initiallized prior to executing this file, but can be initialized here as follows
        -db can be initialized with initDB("./examle_database_filepath.sqlite"), which will create the file and the proper database schema
        -simulation "groups" need to be created manually as well using the insertSimGroup("group description") function
"""
const db_filepath = "./examle_database_filepath.sqlite"
initDB(db_filepath) #optional
const sim_group_id = insertSimGroup("Example Group Description") #optional

"""
Step 4: Include a script that contains all of the setup (i.e., lists of varous parameters) for simulation.
    -setup could be defined in this script, but keeping the setup separate allows for this script to remain unchanged between runs.
"""
include("simulation_setup_example.jl")

"""
Step 5: Construct the model to simulate
    -get the SLURM_ARRAY_TASK_ID environment variable to use to construct the unique model for this slurm task
"""
const slurm_task_id = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])
const model = selectAndConstructModel(game_list=game_list, sim_params_list=sim_params_list, graph_params_list=graph_params_list, starting_condition_list=starting_condition_list, stopping_condition_list=stopping_condition_list, model_number=slurm_task_id)

"""
Step 6: Run simulation on the constructed model
    -add db_filepath to store data in the sqlite file
"""
simulateDistributed(model, db_filepath, run_count=nworkers())


"""
Step 7: Remove excess distributed processes
"""
resetprocs()