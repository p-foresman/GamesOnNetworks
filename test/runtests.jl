using GamesOnNetworks
using Test, BenchmarkTools, Suppressor

@testset "GamesOnNetworks.jl" begin
    include("test_setup.jl")

    # #complete
    # @test @suppress simulateTransitionTime(game, sim_params_1, graph_params_complete, use_seed=true) == 234
    # @test @suppress simulateTransitionTime(game, sim_params_2, graph_params_complete, use_seed=true) == 1250

    # #erdos-renyi
    # @test @suppress simulateTransitionTime(game, sim_params_1, graph_params_er, use_seed=true) == 104
    # @test @suppress simulateTransitionTime(game, sim_params_2, graph_params_er, use_seed=true) == 574

    # #small-world
    # @test @suppress simulateTransitionTime(game, sim_params_1, graph_params_sw, use_seed=true) == 1200
    # @test @suppress simulateTransitionTime(game, sim_params_2, graph_params_sw, use_seed=true) == 4374

    # #scale-free
    # @test @suppress simulateTransitionTime(game, sim_params_1, graph_params_sf, use_seed=true) == 85
    # @test @suppress simulateTransitionTime(game, sim_params_2, graph_params_sf, use_seed=true) == 4466

    # #sbm
    # @test @suppress simulateTransitionTime(game, sim_params_1, graph_params_sbm, use_seed=true) == 2735
    # @test @suppress simulateTransitionTime(game, sim_params_2, graph_params_sbm, use_seed=true) == 13429

    #complete
    @test @suppress simulate(SimModel(game, sim_params_1, graph_params_complete, starting_condition_fractious, stopping_condition_equity_psychological), use_seed=true) == 234
    @test @suppress simulate(SimModel(game, sim_params_2, graph_params_complete, starting_condition_fractious, stopping_condition_equity_psychological), use_seed=true) == 1250

    #erdos-renyi
    @test @suppress simulate(SimModel(game, sim_params_1, graph_params_er, starting_condition_fractious, stopping_condition_equity_psychological), use_seed=true) == 104
    @test @suppress simulate(SimModel(game, sim_params_2, graph_params_er, starting_condition_fractious, stopping_condition_equity_psychological), use_seed=true) == 574

    #small-world
    @test @suppress simulate(SimModel(game, sim_params_1, graph_params_sw, starting_condition_fractious, stopping_condition_equity_psychological), use_seed=true) == 1200
    @test @suppress simulate(SimModel(game, sim_params_2, graph_params_sw, starting_condition_fractious, stopping_condition_equity_psychological), use_seed=true) == 4374

    #scale-free
    @test @suppress simulate(SimModel(game, sim_params_1, graph_params_sf, starting_condition_fractious, stopping_condition_equity_psychological), use_seed=true) == 85
    @test @suppress simulate(SimModel(game, sim_params_2, graph_params_sf, starting_condition_fractious, stopping_condition_equity_psychological), use_seed=true) == 4466

    #sbm
    @test @suppress simulate(SimModel(game, sim_params_1, graph_params_sbm, starting_condition_fractious, stopping_condition_equity_psychological), use_seed=true) == 2735
    @test @suppress simulate(SimModel(game, sim_params_2, graph_params_sbm, starting_condition_fractious, stopping_condition_equity_psychological), use_seed=true) == 13429

    
    benchmark = @suppress begin @benchmark simulate(SimModel(game, sim_params_1, graph_params_complete, starting_condition_fractious, stopping_condition_equity_psychological), use_seed=true) end
    println(benchmark)
    @test mean(benchmark.times) < 7.5e6 #7ms
end