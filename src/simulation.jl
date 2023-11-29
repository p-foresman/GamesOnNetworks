############################### MAIN TRANSITION TIME SIMULATION #######################################
include("simulation_functions.jl")



############################### simulate with no db ################################

function simulate(model::SimModel; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false, to::TimerOutput)
    @timeit to "simulate" begin
    if use_seed == true
        Random.seed!(model.sim_params.random_seed)
    end

    while @timeit to "checkStoppingCondition" !checkStoppingCondition(model.stopping_condition, model.agent_graph, periods_elapsed)
        runPeriod!(model, to)
        periods_elapsed += 1
    end

    println(" --> periods elapsed: $periods_elapsed")
    return periods_elapsed
    end
end

function simulateDistributed(model::SimModel; run_count::Integer = 1, use_seed::Bool = false)
    println("\n\n\n")
    println(displayName(model.graph_params))
    println(dump(model.graph_params))
    print("Number of agents: $(model.sim_params.number_agents), ")
    print("Memory length: $(model.sim_params.memory_length), ")
    println("Error: $(model.sim_params.error)")
    flush(stdout) #flush buffer

    @sync @distributed for run in 1:run_count
        print("Run $run of $run_count")
        flush(stdout)
        simulate(model, use_seed=use_seed)
    end
end

function simulationIterator(model_list::Vector{<:SimModel}; run_count::Integer = 1, use_seed::Bool = false)
    for model in model_list
        println("\n\n\n")
        println(displayName(graph_params))
        println(dump(graph_params))
        print("Number of agents: $(model.sim_params.number_agents), ")
        print("Memory length: $(model.sim_params.memory_length), ")
        println("Error: $(model.sim_params.error)")

        @sync @distributed for run in 1:run_count
            print("Run $run of $run_count")
            flush(stdout)
            simulate(model, use_seed=use_seed)
        end
    end
end




################################# simulate with db_filepath and no db_store_period #####################################

function simulate(model::SimModel,  db_filepath::String; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false, db_sim_group_id::Union{Nothing, Integer} = nothing, db_id_tuple::Union{Nothing, NamedTuple{(:game_id, :graph_id, :sim_params_id, :starting_condition_id, :stopping_condition_id), NTuple{5, Int64}}} = nothing, prev_simulation_uuid::Union{String, Nothing} = nothing, distributed_uuid::Union{String, Nothing} = nothing)
    if use_seed == true && prev_simulation_uuid === nothing #set seed only if the simulation has no past runs
        Random.seed!(model.sim_params.random_seed)
    end

    if db_id_tuple === nothing 
        db_id_tuple = constructIDTuple(model, db_filepath, use_seed=use_seed)
    end

    # @timeit to "simulate" begin
    while !checkStoppingCondition(model.stopping_condition, model.agent_graph, periods_elapsed)
        #play a period worth of games
        # @timeit to "period" runPeriod!(model, to)
        runPeriod!(model)
        periods_elapsed += 1
    end
    # end
    println(" --> periods elapsed: $periods_elapsed")
    flush(stdout) #flush buffer
    db_status = pushSimulationToDB(db_filepath, db_sim_group_id, prev_simulation_uuid, db_id_tuple, model.agent_graph, periods_elapsed, distributed_uuid)
    return (periods_elapsed, db_status)
end


function simulateDistributed(model::SimModel, db_filepath::String; run_count::Integer = 1, use_seed::Bool = false, db_sim_group_id::Union{Integer, Nothing} = nothing)
    distributed_uuid = "$(displayName(model.graph_params))__$(displayName(model.sim_params))_TASKID=$(model.id)"

    if nworkers() > 1
        println("\nSimulation Distributed UUID: $distributed_uuid")
        initDistributedDB(distributed_uuid)
    end

    db_id_tuple = constructIDTuple(model, db_filepath, use_seed=use_seed)

    println("\n\n\n")
    println(displayName(model.graph_params))
    println(dump(model.graph_params))
    print("Number of agents: $(model.sim_params.number_agents), ")
    print("Memory length: $(model.sim_params.memory_length), ")
    println("Error: $(model.sim_params.error)")
    flush(stdout) #flush buffer

    @sync @distributed for run in 1:run_count
        print("Run $run of $run_count")
        flush(stdout)
        simulate(model, db_filepath, use_seed=use_seed, db_sim_group_id=db_sim_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
    end

    if nworkers() > 1
        collectDistributedDB(db_filepath, distributed_uuid)
    end
end


function simulationIterator(model_list::Vector{<:SimModel}, db_filepath::String; run_count::Integer = 1, use_seed::Bool = false, db_sim_group_id::Union{Integer, Nothing} = nothing)
    distributed_uuid = "$(uuid4())"

    if nworkers() > 1
        println("\nSimulation Distributed UUID: $distributed_uuid")
        initDistributedDB(distributed_uuid)
    end

    for model in model_list
        db_id_tuple = constructIDTuple(model, db_filepath, use_seed=use_seed)

        println("\n\n\n")
        println(displayName(model.graph_params))
        println(dump(model.graph_params))
        print("Number of agents: $(model.sim_params.number_agents), ")
        print("Memory length: $(model.sim_params.memory_length), ")
        println("Error: $(model.sim_params.error)")
        flush(stdout) #flush buffer

        @sync @distributed for run in 1:run_count
            print("Run $run of $run_count")
            flush(stdout)
            simulate(model, db_filepath, use_seed=use_seed, db_sim_group_id=db_sim_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
        end
    end

    if nworkers() > 1
        collectDistributedDB(db_filepath, distributed_uuid)
    end
end





################################ simulate with db_filepath and db_store_period ##################################

function simulate(model::SimModel, db_filepath::String, db_store_period::Integer; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false, db_sim_group_id::Union{Nothing, Integer} = nothing, db_id_tuple::Union{Nothing, NamedTuple{(:game_id, :graph_id, :sim_params_id, :starting_condition_id, :stopping_condition_id), NTuple{5, Int64}}} = nothing, prev_simulation_uuid::Union{String, Nothing} = nothing, distributed_uuid::Union{String, Nothing} = nothing)
    if use_seed == true && prev_simulation_uuid === nothing #set seed only if the simulation has no past runs
        Random.seed!(model.sim_params.random_seed)
    end

    if db_id_tuple === nothing 
        db_id_tuple = constructIDTuple(model, db_filepath, use_seed=use_seed)
    end

    # @timeit to "simulate" begin
    db_status = nothing #NOTE: THIS SHOULD BE TYPED
    already_pushed::Bool = false #for the special case that simulation data is pushed to the db periodically and one of these pushes happens to fall on the last period of the simulation
    while !checkStoppingCondition(model.stopping_condition, model.agent_graph, periods_elapsed)
        #play a period worth of games
        # @timeit to "period" runPeriod!(model, to)
        runPeriod!(model)
        periods_elapsed += 1
        already_pushed = false
        if periods_elapsed % db_store_period == 0 #push incremental results to DB
            db_status = pushSimulationToDB(db_filepath, db_sim_group_id, prev_simulation_uuid, db_id_tuple, model.agent_graph, periods_elapsed, distributed_uuid)
            prev_simulation_uuid = db_status.simulation_uuid
            already_pushed = true
        end
    end
    # end
    println(" --> periods elapsed: $periods_elapsed")
    flush(stdout) #flush buffer
    if already_pushed == false #push final results to DB at filepath
        db_status = pushSimulationToDB(db_filepath, db_sim_group_id, prev_simulation_uuid, db_id_tuple, model.agent_graph, periods_elapsed, distributed_uuid)
    end
    return (periods_elapsed, db_status)
end


function simulateDistributed(model::SimModel, db_filepath::String, db_store_period::Integer,; run_count::Integer = 1, use_seed::Bool = false, db_sim_group_id::Union{Integer, Nothing} = nothing)
    distributed_uuid = "$(displayName(model.graph_params))__$(displayName(model.sim_params))_TASKID=$(model.id)"

    
    if nworkers() > 1
        println("\nSimulation Distributed UUID: $distributed_uuid")
        initDistributedDB(distributed_uuid)
    end

    db_id_tuple = constructIDTuple(model, db_filepath, use_seed=use_seed)

    println("\n\n\n")
    println(displayName(model.graph_params))
    println(dump(model.graph_params))
    print("Number of agents: $(model.sim_params.number_agents), ")
    print("Memory length: $(model.sim_params.memory_length), ")
    println("Error: $(model.sim_params.error)")
    flush(stdout) #flush buffer

    @sync @distributed for run in 1:run_count
        print("Run $run of $run_count")
        flush(stdout)
        simulate(model, db_filepath, db_store_period, use_seed=use_seed, db_sim_group_id=db_sim_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
    end

    if nworkers() > 1
        collectDistributedDB(db_filepath, distributed_uuid)
    end
end


function simulationIterator(model_list::Vector{<:SimModel}, db_filepath::String, db_store_period::Integer; run_count::Integer = 1, use_seed::Bool = false, db_sim_group_id::Union{Integer, Nothing} = nothing)
    distributed_uuid = "$(uuid4())"

    if nworkers() > 1
        println("\nSimulation Distributed UUID: $distributed_uuid")
        initDistributedDB(distributed_uuid)
    end

    for model in model_list
        db_id_tuple = constructIDTuple(model, db_filepath, use_seed=use_seed)

        println("\n\n\n")
        println(displayName(model.graph_params))
        println(dump(model.graph_params))
        print("Number of agents: $(model.sim_params.number_agents), ")
        print("Memory length: $(model.sim_params.memory_length), ")
        println("Error: $(model.sim_params.error)")
        flush(stdout) #flush buffer

        @sync @distributed for run in 1:run_count
            print("Run $run of $run_count")
            flush(stdout)
            simulate(model, db_filepath, db_store_period, use_seed=use_seed, db_sim_group_id=db_sim_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
        end
    end

    if nworkers() > 1
        collectDistributedDB(db_filepath, distributed_uuid)
    end
end



# #NOTE: use MVectors for size validation! (sim_params_list_array length should be the same as db_sim_group_id_list length)
# function distributedSimulationIterator(model_list::Vector{SimModel}; run_count::Integer = 1, use_seed::Bool = false, db_filepath::String, db_store_period::Union{Integer, Nothing} = nothing, db_sim_group_id::Integer)
#     slurm_task_id = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])

#     if length(model_list) != parse(Int64, ENV["SLURM_ARRAY_TASK_COUNT"])
#         throw(ErrorException("Slurm array task count and number of models in the model list differ.\nSLURM_ARRAY_TASK_COUNT: $(parse(Int64, ENV["SLURM_ARRAY_TASK_COUNT"]))\nNumber of models: $(length(model_list))"))
#     end

#     model = model_list[slurm_task_id]
     
#     println("\n\n\n")
#     println(displayName(model.graph_params))
#     println(displayName(model.sim_params))
#     flush(stdout) #flush buffer

#     distributed_uuid = "$(displayName(graph_params))__$(displayName(sim_params))_TASKID=$slurm_task_id"
#     initDistributedDB(distributed_uuid)

#     db_id_tuple = (
#                    game_id = pushGameToDB(db_filepath, model.game),
#                    graph_id = pushGraphToDB(db_filepath, model.graph_params),
#                    sim_params_id = pushSimParamsToDB(db_filepath, model.sim_params, use_seed),
#                    starting_condition_id = pushStartingConditionToDB(db_filepath, model.starting_condition),
#                    stopping_condition_id = pushStoppingConditionToDB(db_filepath, model.starting_condition)
#                   )

#     @sync @distributed for run in 1:run_count
#         print("Run $run of $run_count")
#         simulate(model, use_seed=use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_sim_group_id=db_sim_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
#     end

#     if nworkers() > 1
#         collectDistributedDB(db_filepath, distributed_uuid)
#     end
# end



# #NOTE: use MVectors for size validation! (sim_params_list_array length should be the same as db_sim_group_id_list length)
# function distributedSimulationIterator(game::Game, sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, starting_condition::StartingCondition, stopping_condition::StoppingCondition; run_count::Integer = 1, use_seed::Bool = false, db_filepath::String, db_store_period::Union{Integer, Nothing} = nothing, db_sim_group_id::Integer)
#     slurm_task_id = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])
#     graph_count = length(graph_params_list)
#     # sim_params_count = length(sim_params_list)
#     # slurm_array_length = graph_count * sim_params_count
#     graph_index = (slurm_task_id % graph_count) == 0 ? graph_count : slurm_task_id % graph_count
#     graph_params = graph_params_list[graph_index]
#     # sim_params_index = (slurm_task_id % sim_params_count) == 0 ? sim_params_count : slurm_task_id % sim_params_count
#     sim_params_index = ceil(Int64, slurm_task_id / graph_count) #allows for iteration of graph_params over each sim_param
#     sim_params = sim_params_list[sim_params_index]
     
#     println("\n\n\n")
#     println(displayName(graph_params))
#     println(displayName(sim_params))
#     flush(stdout) #flush buffer

#     distributed_uuid = "$(displayName(graph_params))__$(displayName(sim_params))_TASKID=$slurm_task_id"
#     initDistributedDB(distributed_uuid)

#     db_game_id = db_filepath !== nothing ? pushGameToDB(db_filepath, game) : nothing
#     db_graph_id = db_filepath !== nothing ? pushGraphToDB(db_filepath, graph_params) : nothing
#     db_sim_params_id = db_filepath !== nothing ? pushSimParamsToDB(db_filepath, sim_params, use_seed) : nothing

#     @sync @distributed for run in 1:run_count
#         print("Run $run of $run_count")
#         simulate(game, sim_params, graph_params, starting_condition, stopping_condition, use_seed=use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_sim_group_id=db_sim_group_id, db_game_id=db_game_id, db_graph_id=db_graph_id, db_sim_params_id=db_sim_params_id, distributed_uuid=distributed_uuid)
#     end

#     if db_filepath !== nothing && nworkers() > 1
#         collectDistributedDB(db_filepath, distributed_uuid)
#     end
# end



#used to continue a simulation
function simGroupIterator(db_sim_group_id::Integer; db_store::Bool = false, db_filepath::String, db_store_period::Int = 0)
    simulation_ids_df = querySimulationIDsByGroup(db_filepath, db_sim_group_id)
    for row in eachrow(simulation_ids_df)
        continueSimulation(row[:simulation_id], db_store=db_store, db_filepath=db_filepath, db_store_period=db_store_period)
    end
end


function continueSimulation(db_simulation_id::Integer; db_store::Bool = false, db_filepath::String, db_store_period::Integer = 0)
    prev_sim = restoreFromDatabase(db_filepath, db_simulation_id)
    sim_results = simulateTransitionTime(prev_sim.game, prev_sim.sim_params, prev_sim.graph_params, use_seed=prev_sim.use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_sim_group_id=prev_sim.sim_group_id, prev_simulation_uuid=prev_sim.prev_simulation_uuid)
end