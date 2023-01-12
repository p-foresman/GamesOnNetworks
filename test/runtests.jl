using GamesOnNetworks
using Test, BenchmarkTools, Suppressor

@testset "GamesOnNetworks.jl" begin
    include("test_setup.jl")
    @test @suppress simulateTransitionTime(game, sim_params_1, graph_params_complete, use_seed=true) == 543
    @test @suppress simulateTransitionTime(game, sim_params_2, graph_params_complete, use_seed=true) == 3732

    
    benchmark = @suppress begin @benchmark simulateTransitionTime(game, sim_params_1, graph_params_complete, use_seed=true) end
    println(benchmark)
    @test mean(benchmark.times) < 7.5e6 #7ms
end