using GamesOnNetworks
using Test, BenchmarkTools, Suppressor

@testset "GamesOnNetworks.jl" begin
    include("test_setup.jl")

    #complete
    @test @suppress simulateTransitionTime(game, sim_params_1, graph_params_complete, use_seed=true) == 234
    @test @suppress simulateTransitionTime(game, sim_params_2, graph_params_complete, use_seed=true) == 1250

    #erdos-renyi
    @test @suppress simulateTransitionTime(game, sim_params_1, graph_params_er, use_seed=true) == 104
    @test @suppress simulateTransitionTime(game, sim_params_2, graph_params_er, use_seed=true) == 574

    #small-world
    @test @suppress simulateTransitionTime(game, sim_params_1, graph_params_sw, use_seed=true) == 1200
    @test @suppress simulateTransitionTime(game, sim_params_2, graph_params_sw, use_seed=true) == 4374

    #scale-free
    @test @suppress simulateTransitionTime(game, sim_params_1, graph_params_sf, use_seed=true) == 85
    @test @suppress simulateTransitionTime(game, sim_params_2, graph_params_sf, use_seed=true) == 4466

    #sbm
    @test @suppress simulateTransitionTime(game, sim_params_1, graph_params_sbm, use_seed=true) == 2735
    @test @suppress simulateTransitionTime(game, sim_params_2, graph_params_sbm, use_seed=true) == 13429

    
    benchmark = @suppress begin @benchmark simulateTransitionTime(game, sim_params_1, graph_params_complete, use_seed=true) end
    println(benchmark)
    @test mean(benchmark.times) < 7.5e6 #7ms
end