using GamesOnNetworks
using Test, BenchmarkTools, Suppressor

@testset "GamesOnNetworks.jl" begin
    include("test_setup.jl")
    @test simulateTransitionTime(game, sim_params_1, graph_params_complete, use_seed=true) == 543
    @test simulateTransitionTime(game, sim_params_2, graph_params_complete, use_seed=true) == 3732

    # @suppress begin 
    #     benchmark = @benchmark simulateTransitionTime(game, sim_params_1, graph_params_complete, use_seed=true)
    # end
    # @test mean(benchmark.times) < 10
end