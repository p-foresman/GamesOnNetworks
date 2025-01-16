using GamesOnNetworks

include("startingconditions.jl")
include("stoppingconditions.jl")

# function count_models()
#     count = 0
#     for N in [1000]
#         for m in [10] #run more later?
#             for e in 0.1:-0.01:0.05 #go both lower and higher later
#                 for λ in 10:-0.5:3 #run more later
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
#                         # GamesOnNetworks.db_insert_model(Model(bargaining_game, sim_params, StochasticBlockModel(1, 2, 0.01, 0.01)))
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
            for e in 0.1:-0.01:0.02 #go both lower and higher later
                # l_max = N - 1
                for λ in 10:-0.5:3 #run more later
                    for stop in ["partially_reinforced"]
                        user_variables = UserVariables()
                        if stop == "partially_reinforced"
                            user_variables = UserVariables(:period_count=>0)
                        end
                        sim_params = Parameters(N, m, e, "fractious_state", stop, user_variables=user_variables)


                        #ER
                        count += 1
                        # GamesOnNetworks.db_insert_model(Model(bargaining_game, sim_params, ErdosRenyiModel(λ)))



                        #SW
                        for b in 0.0:0.1:1.0
                            count += 1
                            # GamesOnNetworks.db_insert_model(Model(bargaining_game, sim_params, SmallWorldModel(λ, b)))
                        end
                        for b in [0.0001, 0.001, 0.01]
                            count += 1
                            # GamesOnNetworks.db_insert_model(Model(bargaining_game, sim_params, SmallWorldModel(λ, b)))
                        end


                        #SF
                        for a in 2.0:0.1:5
                            count += 1
                            # GamesOnNetworks.db_insert_model(Model(bargaining_game, sim_params, ScaleFreeModel(λ, a)))
                        end


                        #SBM
                        for p in 0.1:0.1:1.0
                            count += 1
                            # GamesOnNetworks.db_insert_model(Model(bargaining_game, sim_params, StochasticBlockModel(λ, 2, p, 0.01)))
                        end

                        count += 1
                        # GamesOnNetworks.db_insert_model(Model(bargaining_game, sim_params, StochasticBlockModel(λ, 2, 0.01, 0.01)))
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
            for e in 0.1:-0.01:0.02 #go both lower and higher later
                # l_max = N - 1
                for λ in 10:-0.5:3 #run more later
                    for stop in ["partially_reinforced"]
                        user_variables = UserVariables()
                        if stop == "partially_reinforced"
                            user_variables = UserVariables(:period_count=>0)
                        end
                        sim_params = Parameters(N, m, e, "fractious_state", stop, user_variables=user_variables)


                        #ER
                        count += 1
                        if count == model_id
                            return Model(bargaining_game, sim_params, ErdosRenyiModel(λ))
                        end


                        #SW
                        for b in 0.0:0.1:1.0
                            count += 1
                            if count == model_id
                                return Model(bargaining_game, sim_params, SmallWorldModel(λ, b))
                            end
                        end
                        for b in [0.0001, 0.001, 0.01]
                            count += 1
                            if count == model_id
                                return Model(bargaining_game, sim_params, SmallWorldModel(λ, b))
                            end
                        end


                        #SF
                        for a in 2.0:0.1:5
                            count += 1
                            if count == model_id
                                return Model(bargaining_game, sim_params, ScaleFreeModel(λ, a))
                            end
                        end


                        #SBM
                        for p in 0.1:0.1:1.0
                            count += 1
                            if count == model_id
                                return Model(bargaining_game, sim_params, StochasticBlockModel(λ, 2, p, 0.01))
                            end
                        end

                        count += 1
                        if count == model_id
                            return Model(bargaining_game, sim_params, StochasticBlockModel(λ, 2, 0.01, 0.01))
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

λs = collect(10:-0.5:3)
N100_m10 = ModelGenerator(
    Game("Bargaining Game", [(0, 0) (0, 0) (70, 30); (0, 0) (50, 50) (50, 30); (30, 70) (30, 50) (30, 30)]),
    [100],
    [10],
    collect(0.1:-0.01:0.05),
    [("fractious_starting_condition", UserVariables())],
    [("equity_behavioral", UserVariables(:period_count=>0))],
    [
        ErdosRenyiModelGenerator(λs),
        SmallWorldModelGenerator(λs, [0.0, 0.0001, 0.001, 0.01, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]),
        ScaleFreeModelGenerator(λs, collect(2.0:0.1:10.0)),
        StochasticBlockModelGenerator(λs, [2], [0.01, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0], [0.01])
    ]
)
volume(vec::Vector{<:Real}...) = prod([length(v) for v in vec])

sw = SmallWorldModelGenerator(λs, [0.0, 0.0001, 0.001, 0.01, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0])
sf = ScaleFreeModelGenerator(λs, collect(2.0:0.1:10.0))
StochasticBlockModelGenerator(λs, [2], [0.01, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0], [0.01])