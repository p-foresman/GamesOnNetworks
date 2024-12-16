using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")

# function count_models()
#     count = 0
#     for N in [1000]
#         for m in [10] #run more later?
#             for e in 0.1:-0.01:0.05 #go both lower and higher later
#                 for l in 10:-0.5:3 #run more later
#                     for stop in ["equity_behavioral"]

#                         #ER
#                         count += 1

#                         #SW
#                         for b in 0.0:0.001:0.3
#                             count += 1
#                         end
#                         for b in 3.5:0.5:1
#                             count += 1
#                         end

#                         #SF
#                         for a in 2.0:0.1:10
#                             count += 1
#                         end

#                         #SBM
#                         for p in 0.1:0.1:1.0
#                             count += 1
#                         end

#                         count += 1
#                         # GamesOnNetworks.db_insert_model(SimModel(bargaining_game, sim_params, StochasticBlockModel(1, 2, 0.01, 0.01)))
#                     end
#                 end
#             end
#         end
#     end
#     return count
# end

function generate_db()
    bargaining_game = Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)])
    count = 0
    for N in [100]
        # println(N)
        for m in [10] #run more later?
            for e in 0.1:-0.01:0.05 #go both lower and higher later
                # l_max = N - 1
                for l in 10:-0.5:3 #run more later
                    for stop in ["equity_behavioral"]
                        user_variables = UserVariables()
                        if stop == "equity_behavioral"
                            user_variables = UserVariables(:period_count=>0)
                        end
                        sim_params = SimParams(N, m, e, "fractious_starting_condition", stop, user_variables=user_variables)


                        #ER
                        count += 1
                        # GamesOnNetworks.db_insert_model(SimModel(bargaining_game, sim_params, ErdosRenyiModel(l)))



                        #SW
                        for b in 0.0:0.1:1.0
                            count += 1
                            # GamesOnNetworks.db_insert_model(SimModel(bargaining_game, sim_params, SmallWorldModel(l, b)))
                        end
                        for b in [0.0001, 0.001, 0.01]
                            count += 1
                            # GamesOnNetworks.db_insert_model(SimModel(bargaining_game, sim_params, SmallWorldModel(l, b)))
                        end


                        #SF
                        for a in 2.0:0.1:10
                            count += 1
                            # GamesOnNetworks.db_insert_model(SimModel(bargaining_game, sim_params, ScaleFreeModel(l, a)))
                        end


                        #SBM
                        for p in 0.1:0.1:1.0
                            count += 1
                            # GamesOnNetworks.db_insert_model(SimModel(bargaining_game, sim_params, StochasticBlockModel(1, 2, p, 0.01)))
                        end

                        count += 1
                        # GamesOnNetworks.db_insert_model(SimModel(bargaining_game, sim_params, StochasticBlockModel(1, 2, 0.01, 0.01)))
                    end
                end
            end
        end
    end
    return count
end

function get_model_from_generator(model_id::Integer)
    bargaining_game = Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)])
    count = 0
    for N in [100]
        # println(N)
        for m in [10] #run more later?
            for e in 0.1:-0.01:0.05 #go both lower and higher later
                # l_max = N - 1
                for l in 10:-0.5:3 #run more later
                    for stop in ["equity_behavioral"]
                        user_variables = UserVariables()
                        if stop == "equity_behavioral"
                            user_variables = UserVariables(:period_count=>0)
                        end
                        sim_params = SimParams(N, m, e, "fractious_starting_condition", stop, user_variables=user_variables)


                        #ER
                        count += 1
                        if count == model_id
                            return SimModel(bargaining_game, sim_params, ErdosRenyiModel(l))
                        end


                        #SW
                        for b in 0.0:0.1:1.0
                            count += 1
                            if count == model_id
                                return SimModel(bargaining_game, sim_params, SmallWorldModel(l, b))
                            end
                        end
                        for b in [0.0001, 0.001, 0.01]
                            count += 1
                            if count == model_id
                                return SimModel(bargaining_game, sim_params, SmallWorldModel(l, b))
                            end
                        end


                        #SF
                        for a in 2.0:0.1:10
                            count += 1
                            if count == model_id
                                return SimModel(bargaining_game, sim_params, ScaleFreeModel(l, a))
                            end
                        end


                        #SBM
                        for p in 0.1:0.1:1.0
                            count += 1
                            if count == model_id
                                return SimModel(bargaining_game, sim_params, StochasticBlockModel(1, 2, p, 0.01))
                            end
                        end

                        count += 1
                        if count == model_id
                            return SimModel(bargaining_game, sim_params, StochasticBlockModel(1, 2, 0.01, 0.01))
                        end
                    end
                end
            end
        end
    end
end

function get_model_id(process_num, num_processes_in_job)
    return (process_num % num_processes_in_job) + 1
end