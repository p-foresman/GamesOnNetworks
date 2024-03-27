using HypothesisTests, Distributions, StatsPlots, StatsBase, Graphs


TestType = ApproximateTwoSampleKSTest

N = 50
d = 0.5
e_possible = (N * (N-1)) / 2
e = Int(round(d * e_possible))
expected_degree = Int(round(N * d)) #(N*edge_prob)

rewiring_prob = 0.1


function scale_free(n::Int, α::Int; m_scaler::Float64 = 0.5)
    m_possible = (n * (n-1)) / 2
    m = Int(round(m_scaler * m_possible))
    # println(m)
    return static_scale_free(n, m, α)
end

# dist = Pareto(alpha, theta)
# X = rand(dist, samples)
# test = TestType(X, dist)
# p = pvalue(test)
# hist = histogram(X; bins = 50, normalize = :pdf, label = "pvalue = $(round(p; digits=3))")
# xrange = range(1, maximum(X); length = 100)
# plot!(xrange, pdf.(dist, xrange); color = :black, label = "analytic")
# # axislegend(ax)
# hist
er_graph = erdos_renyi(N, e)
er_degrees = degree(er_graph)
println("er: ", ne(er_graph))


sf_graph = scale_free(N, 2, m_scaler=d)
sf_degrees = degree(sf_graph)
println("sf: ", ne(sf_graph))


sw_graph = watts_strogatz(N, expected_degree, rewiring_prob)
sw_degrees = degree(sw_graph)
println("sw: ", ne(sw_graph))


# sf_graph = scale_free(nodes, alpha, m_scaler=scaler)
# degrees = degree(sf_graph)

# plot(degrees)


test = TestType(er_degrees, sw_degrees)
p = pvalue(test)

hist = histogram([er_degrees sw_degrees]; bins = 50, normalize = :pdf, label = ["ER = $(round(p; digits=3))" "SW = $(round(p; digits=3))"], fillalpha=0.4)
# xrange = range(0, maximum(er_degrees); length = 100)
# histogram(er_degrees; bins = 50, normalize = :pdf)
# histogram!(xrange, er_degrees; color = :black, label = "analytic")
# axislegend(ax)
hist
# samples = 10000
# pareto_dist = Pareto(1.38, 1)
# X = map(x->round(x), rand(pareto_dist, samples))
# histogram(X)
# plot(sort(X, rev=true))
# plot(pareto_dist, xlims=[0, 10])
# hist_data = countmap(X)
# frequency_dist = sort([frequency / samples for frequency in values(hist_data)], rev=true)
# plot(frequency_dist)
# p = OneSampleADTest(frequency_dist, pareto_dist)
# ks = ApproximateOneSampleKSTest(frequency_dist, pareto_dist)


# """
# Notes:
# ER and SF are p<0.05 at N=50 and p<0.01 at N=60
# SW approaches an ER graph as rewiring probability (β) goes to 1.0 (at 0.0, the graph is regular)
#     -keep β small for a sufficiently different degree distribution
#     -choose β values 0.0, 0.05, 0.1? (definitely 0.0 for regular lattice)
#     -for β=0.05, p<0.05 at N=50, for β=0.1, p<0.5 at
# """