############################### MAIN TRANSITION TIME SIMULATION #######################################
include("simulation_functions.jl")


function simulate(game::Game, sim_params::SimParams, graph_params::GraphParams, starting_condition::StartingCondition, stopping_condition::StoppingCondition; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false, db_filepath::Union{String, Nothing} = nothing, db_store_period::Union{Integer, Nothing} = nothing, db_sim_group_id::Union{Integer, Nothing} = nothing, db_game_id::Union{Integer, Nothing} = nothing, db_graph_id::Union{Integer, Nothing} = nothing, db_sim_params_id::Union{Integer, Nothing} = nothing, prev_simulation_uuid::Union{String, Nothing} = nothing, distributed_uuid::Union{String, Nothing} = nothing)
    if use_seed == true && prev_simulation_uuid === nothing #set seed only if the simulation has no past runs
        Random.seed!(sim_params.random_seed)
    end

    #set up stopping condition sim_params specific fields
    # stopping_condition.agent_threshold = (1 - sim_params.error) * sim_params.number_agents #this is now calculated within checkStoppingCondition() to factor in hermits
    initStoppingCondition!(stopping_condition, sim_params)

    #create graph and subsequent metagraph to hold node metadata (associate node with agent object)
    agent_graph = initGraph(graph_params, game, sim_params, starting_condition)
    graph_edges = collect(edges(agent_graph.graph)) #collect here to avoid excessive allocations in loop (collect() is DANGEROUS in loop)
    #println(graph.fadjlist)
    #println(adjacency_matrix(graph)[1, 2])

    #play game until transition occurs (sufficient equity is reached)
    pre_allocated_arrays = PreAllocatedArrays(game.payoff_matrix) #construct these arrays outside of main loop to avoid excessive allocations
    # opponent_strategy_recollection = zeros.(Int64, size(game.payoff_matrix))
    # opponent_strategy_probs = zeros.(Float64, size(game.payoff_matrix))
    # player_expected_utilities = zeros.(Float32, size(game.payoff_matrix))

    already_pushed::Bool = false #for the special case that simulation data is pushed to the db periodically and one of these pushes happens to fall on the last period of the simulation
    while !checkStoppingCondition(stopping_condition, agent_graph, sim_params, periods_elapsed)
        #play a period worth of games
        runPeriod!(agent_graph, graph_edges, game, sim_params, pre_allocated_arrays)
        periods_elapsed += 1
        already_pushed = false
        if db_filepath !== nothing && db_store_period !== nothing && periods_elapsed % db_store_period == 0 #push incremental results to DB
            db_status = pushSimulationToDB(db_filepath, db_sim_group_id, prev_simulation_uuid, db_game_id, db_graph_id, db_sim_params_id, agent_graph, periods_elapsed, distributed_uuid)
            prev_simulation_uuid = db_status.simulation_uuid
            already_pushed = true
        end
    end
    println(" --> periods elapsed: $periods_elapsed")
    flush(stdout) #flush buffer
    if db_filepath !== nothing && already_pushed == false #push final results to DB at filepath
        db_status = pushSimulationToDB(db_filepath, db_sim_group_id, prev_simulation_uuid, db_game_id, db_graph_id, db_sim_params_id, agent_graph, periods_elapsed, distributed_uuid)
        return (periods_elapsed, db_status)
    end
    return periods_elapsed
end


function simulationIterator(game::Game, sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, starting_condition::StartingCondition, stopping_condition::StoppingCondition; run_count::Integer = 1, use_seed::Bool = false, db_filepath::Union{String, Nothing} = nothing, db_store_period::Union{Integer, Nothing} = nothing, db_sim_group_id::Union{Integer, Nothing} = nothing)
    distributed_uuid = "$(uuid4())"
    
    if db_filepath === nothing && db_sim_group_id !== nothing
        throw(ArgumentError("The dm_sim_group_id parameter was specified without a db_filepath. Provide a db_filepath to store to database"))
    end

    if db_filepath !== nothing && nworkers() > 1
        println("\nSimulation Distributed UUID: $distributed_uuid")
        initDistributedDB(distributed_uuid)
    end

    db_game_id = db_filepath !== nothing ? pushGameToDB(db_filepath, game) : nothing

    for graph_params in graph_params_list
        println("\n\n\n")
        println(displayName(graph_params))
        println(dump(graph_params))

        db_graph_id = db_filepath !== nothing ? pushGraphToDB(db_filepath, graph_params) : nothing

        for sim_params in sim_params_list            
            print("Number of agents: $(sim_params.number_agents), ")
            print("Memory length: $(sim_params.memory_length), ")
            println("Error: $(sim_params.error)")
            flush(stdout) #flush buffer

            db_sim_params_id = db_filepath !== nothing ? pushSimParamsToDB(db_filepath, sim_params, use_seed) : nothing

            # run simulation
            @sync @distributed for run in 1:run_count
                print("Run $run of $run_count")
                simulate(game, sim_params, graph_params, starting_condition, stopping_condition, use_seed=use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_sim_group_id=db_sim_group_id, db_game_id=db_game_id, db_graph_id=db_graph_id, db_sim_params_id=db_sim_params_id, distributed_uuid=distributed_uuid)
            end
        end
    end

    if db_filepath !== nothing && nworkers() > 1
        collectDistributedDB(db_filepath, distributed_uuid)
    end
end

#NOTE: use MVectors for size validation! (sim_params_list_array length should be the same as db_sim_group_id_list length)
function distributedSimulationIterator(game::Game, sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, starting_condition::StartingCondition, stopping_condition::StoppingCondition; run_count::Integer = 1, use_seed::Bool = false, db_filepath::String, db_store_period::Union{Integer, Nothing} = nothing, db_sim_group_id::Integer)
    slurm_task_id = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])
    graph_count = length(graph_params_list)
    # sim_params_count = length(sim_params_list)
    # slurm_array_length = graph_count * sim_params_count
    graph_index = (slurm_task_id % graph_count) == 0 ? graph_count : slurm_task_id % graph_count
    graph_params = graph_params_list[graph_index]
    # sim_params_index = (slurm_task_id % sim_params_count) == 0 ? sim_params_count : slurm_task_id % sim_params_count
    sim_params_index = ceil(Int64, slurm_task_id / graph_count) #allows for iteration of graph_params over each sim_param
    sim_params = sim_params_list[sim_params_index]
     
    println("\n\n\n")
    println(displayName(graph_params))
    println(displayName(sim_params))
    flush(stdout) #flush buffer

    distributed_uuid = "$(displayName(graph_params))__$(displayName(sim_params))_TASKID=$slurm_task_id"
    initDistributedDB(distributed_uuid)

    db_game_id = db_filepath !== nothing ? pushGameToDB(db_filepath, game) : nothing
    db_graph_id = db_filepath !== nothing ? pushGraphToDB(db_filepath, graph_params) : nothing
    db_sim_params_id = db_filepath !== nothing ? pushSimParamsToDB(db_filepath, sim_params, use_seed) : nothing

    @sync @distributed for run in 1:run_count
        print("Run $run of $run_count")
        simulate(game, sim_params, graph_params, starting_condition, stopping_condition, use_seed=use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_sim_group_id=db_sim_group_id, db_game_id=db_game_id, db_graph_id=db_graph_id, db_sim_params_id=db_sim_params_id, distributed_uuid=distributed_uuid)
    end

    if db_filepath !== nothing && nworkers() > 1
        collectDistributedDB(db_filepath, distributed_uuid)
    end
end



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