############################### MAIN TRANSITION TIME SIMULATION #######################################

#NOTE: clean this stuff up

# function timeout(model::SimModel, db_info::Union{Nothing, DBInfo}; exit_code::Int=85)
#     if isnothing(SETTINGS.database) #if database functionality isn't active, simply exit when timeout is reached
#         return () -> exit(exit_code)
#     else
#         return () -> (begin
#             db_checkpoint(db_info, db_info, exit_code=exit_code)
#             exit(exit_code)
#         end)
#     end
# end

"""
    simulate(model::SimModel; db_group_id::Union{Nothing, Integer} = nothing, preserve_graph::Bool=false)

Run a simulation using the model provided.
"""
function simulate(model::SimModel; db_group_id::Union{Nothing, Integer} = nothing, preserve_graph::Bool=false)
    # timer = Timer(timeout(model, SETTINGS.database))
    _simulate_model_buffer(model, SETTINGS.database)
    # _simulate_distributed_barrier(model, SETTINGS.database, db_group_id=db_group_id, preserve_graph=preserve_graph)
end


"""
    simulate(model_id::Int; db_group_id::Union{Nothing, Integer} = nothing, preserve_graph::Bool=false)

Run a simulation using a model stored in the configured database with the given model_id. The model will be reconstructed to be used in the simulation.
Note: a database must be configured to use this method and a model with the given model_id must exist in the configured database.
"""
function simulate(model_id::Int; db_group_id::Union{Nothing, Integer} = nothing, preserve_graph::Bool=false)
    @assert !isnothing(SETTINGS.database) "Cannot use 'simulate(model_id::Int)' method without a database configured."

    # timer = Timer(timeout(model, SETTINGS.database))
    _simulate_model_buffer(model_id, SETTINGS.database)
    # _simulate_distributed_barrier(model, SETTINGS.database, db_group_id=db_group_id, preserve_graph=preserve_graph)

    # if nworkers() > 1
    #     return _simulate_distributed_barrier(model, SETTINGS.database, db_group_id=db_group_id, preserve_graph=preserve_graph)
    # else
    #     return _simulate(model, SETTINGS.database, periods_elapsed=periods_elapsed, db_group_id=db_group_id, prev_simulation_uuid=prev_simulation_uuid, distributed_uuid=distributed_uuid)
    # end
end

# function simulate(model_list::Vector{<:SimModel}; preserve_graph::Bool=false)
#     for model in model_list
#         show(model)
#         flush(stdout)

#         simulate(model, preserve_graph)
#     end
# end


function _simulate_model_barrier(model::SimModel, ::Nothing; preserve_graph::Bool=false, kwargs...)
    _simulate_distributed_barrier(model; preserve_graph=preserve_graph)
end

function _simulate_model_barrier(model::SimModel, db_info::DBInfo; db_group_id::Union{Nothing, Integer} = nothing, preserve_graph::Bool=false)
    model_id = db_insert_model(db_info, model, SETTINGS.use_seed)
    _simulate_distributed_barrier(model, db_info; model_id=model_id, db_group_id=db_group_id, preserve_graph=preserve_graph)

end

function _simulate_model_barrier(model_id::Int, db_info::DBInfo; db_group_id::Union{Nothing, Integer} = nothing, preserve_graph::Bool=false)
    # @assert !isnothing(SETTINGS.database) "Cannot use 'simulate(model_id::Int)' method without a database configured."
    model = db_get_model(model_id) #construct model associated with id
    _simulate_distributed_barrier(model, db_info; model_id=model_id, db_group_id=db_group_id, preserve_graph=preserve_graph)
end



function _simulate_distributed_barrier(model::SimModel; preserve_graph::Bool=false, kwargs...) #NOTE: should preserve_graph be in simparams?
    show(model)
    flush(stdout) #flush buffer

    @sync @distributed for process in 1:nworkers()
        print("Process $process of $(nworkers())")
        flush(stdout)
        if !preserve_graph
            model = regenerate_model(model)
        end
        _simulate(model)
    end
end


function _simulate_distributed_barrier(model::SimModel, db_info::SQLiteInfo; model_id::Int, db_group_id::Union{Integer, Nothing} = nothing, preserve_graph::Bool=false)
    # sim_model_id = db_insert_model(db_info, model, SETTINGS.use_seed)
    # if isnothing(model_id(model))
        
    # end
    distributed_uuid = "$(displayname(game(model)))__$(displayname(graphmodel(model)))__$(displayname(simparams(model)))__Start=$(displayname(startingcondition(model)))__Stop=$(displayname(stoppingcondition(model)))__MODELID=$model_id"

    if nworkers() > 1
        println("\nSimulation Distributed UUID: $distributed_uuid")
        db_init_distributed(distributed_uuid)
    end

    # db_id_tuple = db_construct_id_tuple(db_info, model, SETTINGS.use_seed)
    # sim_model_id = db_insert_model(db_info, model, SETTINGS.use_seed)
    # if isnothing(model_id(model))
        
    # end

    show(model)
    flush(stdout) #flush buffer

    @sync @distributed for process in 1:nworkers() #NOTE: run_count could be number workers
        print("Process $process of $(nworkers())")
        flush(stdout)
        if !preserve_graph
            model = regenerate_model(model)
        end
        _simulate(model, db_info, model_id=model_id, db_group_id=db_group_id, distributed_uuid=distributed_uuid) #db_id_tuple=db_id_tuple
    end

    if nworkers() > 1
        db_collect_temp(db_info, distributed_uuid, cleanup_directory=true)
    end
end


function _simulate_distributed_barrier(model::SimModel, db_info::PostgresInfo; model_id::Int, db_group_id::Union{Integer, Nothing} = nothing, preserve_graph::Bool=false)

    show(model)
    flush(stdout) #flush buffer

    @sync @distributed for process in 1:nworkers() #NOTE: run_count could be number workers
        print("Process $process of $(nworkers())")
        flush(stdout)
        if !preserve_graph
            model = regenerate_model(model)
        end
        _simulate(model, db_info, model_id=model_id, db_group_id=db_group_id)
    end
end




function _simulate(model::SimModel; periods_elapsed::Int128 = Int128(0), kwargs...)
    if SETTINGS.use_seed && isnothing(prev_simulation_uuid) #set seed only if the simulation has no past runs (NOTE: is prev_simulation_uuid needed here?? not running with db)
        Random.seed!(random_seed(model))
    end

    while !is_stopping_condition(model, stoppingcondition(model), periods_elapsed)
        run_period!(model)
        periods_elapsed += 1
    end

    println(" --> periods elapsed: $periods_elapsed")
    return periods_elapsed
end

function _simulate(model::SimModel, db_info::DBInfo; model_id::Int, periods_elapsed::Int128 = Int128(0), db_group_id::Union{Nothing, Integer} = nothing, prev_simulation_uuid::Union{String, Nothing} = nothing, distributed_uuid::Union{String, Nothing} = nothing)
    if SETTINGS.use_seed && isnothing(prev_simulation_uuid) #set seed only if the simulation has no past runs
        Random.seed!(random_seed(model))
    end


    # if isnothing(db_id_tuple)
    #     db_id_tuple = db_construct_id_tuple(db_info, model, SETTINGS.use_seed)
    # end


    # @timeit to "simulate" begin
    while !is_stopping_condition(model, stoppingcondition(model), periods_elapsed)
        #play a period worth of games
        # @timeit to "period" runPeriod!(model, to)
        run_period!(model)
        periods_elapsed += 1
    end
    # end
    println(" --> periods elapsed: $periods_elapsed")
    flush(stdout) #flush buffer
    db_status = db_insert_simulation(db_info, db_group_id, prev_simulation_uuid, model_id, agentgraph(model), periods_elapsed, distributed_uuid)
    return (periods_elapsed, db_status)
end











############################### simulate with no db ################################

# function simulate(model::SimModel; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false)
#     if use_seed == true
#         Random.seed!(random_seed(model))
#     end

#     while !is_stopping_condition(model, stoppingcondition(model), periods_elapsed)
#         run_period!(model)
#         periods_elapsed += 1
#     end

#     println(" --> periods elapsed: $periods_elapsed")
#     return periods_elapsed
# end

# function simulate_distributed(model::SimModel; run_count::Integer = 1, use_seed::Bool = false, preserve_graph::Bool=false) #NOTE: should preserve_graph be in simparams?
#     show(model)
#     flush(stdout) #flush buffer

#     @sync @distributed for run in 1:run_count
#         print("Run $run of $run_count")
#         flush(stdout)
#         if !preserve_graph
#             model = regenerate_model(model)
#         end
#         simulate(model, use_seed=use_seed)
#     end
# end

# function simulation_iterator(model_list::Vector{<:SimModel}; run_count::Integer = 1, use_seed::Bool = false, preserve_graph::Bool=false)
#     for model in model_list
#         show(model)
#         flush(stdout)

#         @sync @distributed for run in 1:run_count
#             print("Run $run of $run_count")
#             flush(stdout)
#             if !preserve_graph
#                 model = regenerate_model(model)
#             end
#             simulate(model, use_seed=use_seed)
#         end
#     end
# end




################################# simulate with db_filepath and no db_store_period #####################################



# function simulate(model::SimModel,  db_filepath::String; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false, db_group_id::Union{Nothing, Integer} = nothing, db_id_tuple::Union{Nothing, DatabaseIdTuple} = nothing, prev_simulation_uuid::Union{String, Nothing} = nothing, distributed_uuid::Union{String, Nothing} = nothing)
#     if use_seed == true && prev_simulation_uuid === nothing #set seed only if the simulation has no past runs
#         Random.seed!(random_seed(model))
#     end

#     if db_id_tuple === nothing 
#         db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)
#     end

#     # @timeit to "simulate" begin
#     while !is_stopping_condition(model, stoppingcondition(model), periods_elapsed)
#         #play a period worth of games
#         # @timeit to "period" runPeriod!(model, to)
#         run_period!(model)
#         periods_elapsed += 1
#     end
#     # end
#     println(" --> periods elapsed: $periods_elapsed")
#     flush(stdout) #flush buffer
#     db_status = db_insert_simulation(db_filepath, db_group_id, prev_simulation_uuid, db_id_tuple, agentgraph(model), periods_elapsed, distributed_uuid)
#     return (periods_elapsed, db_status)
# end


# function simulate_distributed(model::SimModel, db_filepath::String; run_count::Integer = 1, use_seed::Bool = false, db_group_id::Union{Integer, Nothing} = nothing, preserve_graph::Bool=false)
#     distributed_uuid = "$(displayname(game(model)))__$(displayname(graphmodel(model)))__$(displayname(simparams(model)))__Start=$(displayname(startingcondition(model)))__Stop=$(displayname(stoppingcondition(model)))__MODELID=$model_id"

#     if nworkers() > 1
#         println("\nSimulation Distributed UUID: $distributed_uuid")
#         db_init_distributed(distributed_uuid)
#     end

#     db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)

#     show(model)
#     flush(stdout) #flush buffer

#     @sync @distributed for run in 1:run_count
#         print("Run $run of $run_count")
#         flush(stdout)
#         if !preserve_graph
#             model = regenerate_model(model)
#         end
#         simulate(model, db_filepath, use_seed=use_seed, db_group_id=db_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
#     end

#     if nworkers() > 1
#         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
#     end
# end


# function simulation_iterator(model_list::Vector{<:SimModel}, db_filepath::String; run_count::Integer = 1, use_seed::Bool = false, db_group_id::Union{Integer, Nothing} = nothing, preserve_graph::Bool=false)
#     distributed_uuid = "$(uuid4())"

#     if nworkers() > 1
#         println("\nSimulation Distributed UUID: $distributed_uuid")
#         db_init_distributed(distributed_uuid)
#     end

#     for model in model_list
#         db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)

#         show(model)
#         flush(stdout) #flush buffer

#         @sync @distributed for run in 1:run_count
#             print("Run $run of $run_count")
#             flush(stdout)
#             if !preserve_graph
#                 model = regenerate_model(model)
#             end
#             simulate(model, db_filepath, use_seed=use_seed, db_group_id=db_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
#         end
#     end

#     if nworkers() > 1
#         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
#     end
# end





# ################################ simulate with db_filepath and db_store_period ##################################

# function simulate(model::SimModel, db_filepath::String, db_store_period::Integer; periods_elapsed::Int128 = Int128(0), use_seed::Bool = false, db_group_id::Union{Nothing, Integer} = nothing, db_id_tuple::Union{Nothing, DatabaseIdTuple} = nothing, prev_simulation_uuid::Union{String, Nothing} = nothing, distributed_uuid::Union{String, Nothing} = nothing)
#     if use_seed == true && prev_simulation_uuid === nothing #set seed only if the simulation has no past runs
#         Random.seed!(random_seed(model))
#     end

#     if db_id_tuple === nothing 
#         db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)
#     end

#     # @timeit to "simulate" begin
#     db_status = nothing #NOTE: THIS SHOULD BE TYPED
#     already_pushed::Bool = false #for the special case that simulation data is pushed to the db periodically and one of these pushes happens to fall on the last period of the simulation
#     while !is_stopping_condition(model, stoppingcondition(model), periods_elapsed)
#         #play a period worth of games
#         # @timeit to "period" runPeriod!(model, to)
#         run_period!(model)
#         periods_elapsed += 1
#         already_pushed = false
#         if periods_elapsed % db_store_period == 0 #push incremental results to DB
#             db_status = db_insert_simulation(db_filepath, db_group_id, prev_simulation_uuid, db_id_tuple, agentgraph(model), periods_elapsed, distributed_uuid)
#             prev_simulation_uuid = db_status.simulation_uuid
#             already_pushed = true
#         end
#     end
#     # end
#     println(" --> periods elapsed: $periods_elapsed")
#     flush(stdout) #flush buffer
#     if already_pushed == false #push final results to DB at filepath
#         db_status = db_insert_simulation(db_filepath, db_group_id, prev_simulation_uuid, db_id_tuple, agentgraph(model), periods_elapsed, distributed_uuid)
#     end
#     return (periods_elapsed, db_status)
# end


# function simulate_distributed(model::SimModel, db_filepath::String, db_store_period::Integer; run_count::Integer = 1, use_seed::Bool = false, db_group_id::Union{Integer, Nothing} = nothing, preserve_graph::Bool=false)
#     distributed_uuid = "$(displayname(game(model)))__$(displayname(graphmodel(model)))__$(displayname(simparams(model)))__Start=$(displayname(startingcondition(model)))__Stop=$(displayname(stoppingcondition(model)))__MODELID=$model_id"

    
#     if nworkers() > 1
#         println("\nSimulation Distributed UUID: $distributed_uuid")
#         db_init_distributed(distributed_uuid)
#     end

#     db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)

#     show(model)
#     flush(stdout) #flush buffer

#     @sync @distributed for run in 1:run_count
#         print("Run $run of $run_count")
#         flush(stdout)
#         if !preserve_graph
#             model = regenerate_model(model)
#         end
#         simulate(model, db_filepath, db_store_period, use_seed=use_seed, db_group_id=db_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
#     end

#     if nworkers() > 1
#         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
#     end
# end


# function simulation_iterator(model_list::Vector{<:SimModel}, db_filepath::String, db_store_period::Integer; run_count::Integer = 1, use_seed::Bool = false, db_group_id::Union{Integer, Nothing} = nothing, preserve_graph::Bool=false)
#     distributed_uuid = "$(uuid4())"

#     if nworkers() > 1
#         println("\nSimulation Distributed UUID: $distributed_uuid")
#         db_init_distributed(distributed_uuid)
#     end

#     for model in model_list
#         db_id_tuple = db_construct_id_tuple(model, db_filepath, use_seed=use_seed)

#         show(model)
#         flush(stdout) #flush buffer

#         @sync @distributed for run in 1:run_count
#             print("Run $run of $run_count")
#             flush(stdout)
#             if !preserve_graph
#                 model = regenerate_model(model)
#             end
#             simulate(model, db_filepath, db_store_period, use_seed=use_seed, db_group_id=db_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
#         end
#     end

#     if nworkers() > 1
#         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
#     end
# end



# # #NOTE: use MVectors for size validation! (sim_params_list_array length should be the same as db_group_id_list length)
# # function distributedSimulationIterator(model_list::Vector{SimModel}; run_count::Integer = 1, use_seed::Bool = false, db_filepath::String, db_store_period::Union{Integer, Nothing} = nothing, db_group_id::Integer)
# #     slurm_task_id = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])

# #     if length(model_list) != parse(Int64, ENV["SLURM_ARRAY_TASK_COUNT"])
# #         throw(ErrorException("Slurm array task count and number of models in the model list differ.\nSLURM_ARRAY_TASK_COUNT: $(parse(Int64, ENV["SLURM_ARRAY_TASK_COUNT"]))\nNumber of models: $(length(model_list))"))
# #     end

# #     model = model_list[slurm_task_id]
     
# #     println("\n\n\n")
# #     println(displayname(model.graphmodel))
# #     println(displayname(model.simparams))
# #     flush(stdout) #flush buffer

# #     distributed_uuid = "$(displayname(graphmodel))__$(displayname(simparams))_MODELID=$slurm_task_id"
# #     db_init_distributed(distributed_uuid)

# #     db_id_tuple = (
# #                    game_id = pushGameToDB(db_filepath, model.game),
# #                    graph_id = pushGraphToDB(db_filepath, model.graphmodel),
# #                    sim_params_id = pushSimParamsToDB(db_filepath, model.simparams, use_seed),
# #                    starting_condition_id = pushStartingConditionToDB(db_filepath, model.startingcondition),
# #                    stopping_condition_id = pushStoppingConditionToDB(db_filepath, model.startingcondition)
# #                   )

# #     @sync @distributed for run in 1:run_count
# #         print("Run $run of $run_count")
# #         simulate(model, use_seed=use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_group_id=db_group_id, db_id_tuple=db_id_tuple, distributed_uuid=distributed_uuid)
# #     end

# #     if nworkers() > 1
# #         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
# #     end
# # end



# # #NOTE: use MVectors for size validation! (sim_params_list_array length should be the same as db_group_id_list length)
# # function distributedSimulationIterator(game::Game, sim_params_list::Vector{SimParams}, graph_params_list::Vector{<:GraphParams}, startingcondition::StartingCondition, stoppingcondition::StoppingCondition; run_count::Integer = 1, use_seed::Bool = false, db_filepath::String, db_store_period::Union{Integer, Nothing} = nothing, db_group_id::Integer)
# #     slurm_task_id = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])
# #     graph_count = length(graph_params_list)
# #     # sim_params_count = length(sim_params_list)
# #     # slurm_array_length = graph_count * sim_params_count
# #     graph_index = (slurm_task_id % graph_count) == 0 ? graph_count : slurm_task_id % graph_count
# #     graphmodel = graph_params_list[graph_index]
# #     # sim_params_index = (slurm_task_id % sim_params_count) == 0 ? sim_params_count : slurm_task_id % sim_params_count
# #     sim_params_index = ceil(Int64, slurm_task_id / graph_count) #allows for iteration of graphmodel over each sim_param
# #     simparams = sim_params_list[sim_params_index]
     
# #     println("\n\n\n")
# #     println(displayname(graphmodel))
# #     println(displayname(simparams))
# #     flush(stdout) #flush buffer

# #     distributed_uuid = "$(displayname(graphmodel))__$(displayname(simparams))_MODELID=$slurm_task_id"
# #     db_init_distributed(distributed_uuid)

# #     db_game_id = db_filepath !== nothing ? pushGameToDB(db_filepath, game) : nothing
# #     db_graph_id = db_filepath !== nothing ? pushGraphToDB(db_filepath, graphmodel) : nothing
# #     db_sim_params_id = db_filepath !== nothing ? pushSimParamsToDB(db_filepath, simparams, use_seed) : nothing

# #     @sync @distributed for run in 1:run_count
# #         print("Run $run of $run_count")
# #         simulate(game, simparams, graphmodel, startingcondition, stoppingcondition, use_seed=use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_group_id=db_group_id, db_game_id=db_game_id, db_graph_id=db_graph_id, db_sim_params_id=db_sim_params_id, distributed_uuid=distributed_uuid)
# #     end

# #     if db_filepath !== nothing && nworkers() > 1
# #         db_collect_temp(db_filepath, distributed_uuid, cleanup_directory=true)
# #     end
# # end



# #used to continue a simulation
# # function simGroupIterator(db_group_id::Integer; db_store::Bool = false, db_filepath::String, db_store_period::Int = 0)
# #     simulation_ids_df = querySimulationIDsByGroup(db_filepath, db_group_id)
# #     for row in eachrow(simulation_ids_df)
# #         continueSimulation(row[:simulation_id], db_store=db_store, db_filepath=db_filepath, db_store_period=db_store_period)
# #     end
# # end


# # function continueSimulation(db_simulation_id::Integer; db_store::Bool = false, db_filepath::String, db_store_period::Integer = 0)
# #     prev_sim = db_restore_model(db_filepath, db_simulation_id)
# #     sim_results = simulateTransitionTime(prev_sim.game, prev_sim.simparams, prev_sim.graphmodel, use_seed=prev_sim.use_seed, db_filepath=db_filepath, db_store_period=db_store_period, db_group_id=prev_sim.sim_group_id, prev_simulation_uuid=prev_sim.prev_simulation_uuid)
# # end