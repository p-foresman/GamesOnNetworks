########## This script shows the order of steps to run simulations ###########

## 1: add processess if you want simulations to run in a distributed manner
using Distributed
addprocs(20; exeflags="--project") #defines the run count

## 2: import the main module on all processes
@everywhere using GamesOnNetworks


## 3: initiallize sqlite file with proper schema if it doesn't already exist at the filepath
const db_filepath = "./BehavioralSimulationSaves_50.sqlite"
# initDataBase(db_filepath)
#NOTE: simulation groups must be created manually. Use insertSimGroup("description") to insert group. Returns the group_id in 'insert_row_id' field.
# const sim_group_id = insertSimGroup(db_filepath, "Memory Length Iteration, N=50").insert_row_id #should be 4



const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])

const game = Game{3, 3}("Bargaining Game", payoff_matrix)
const sim_params = SimParams(50, 19, 0.05)
const graph_params = CompleteParams()
const starting_condition = FractiousState()
const stopping_condition = EquityBehavioral(2)
const model = SimModel(game, sim_params, graph_params, starting_condition, stopping_condition)

## 5: run simulation
simulateDistributed(model, db_filepath, run_count=nworkers(), db_sim_group_id=4)



##6: remove worker cores
if nprocs() > 1
    for id in workers()
        rmprocs(id)
    end
end