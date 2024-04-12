# using Distributed
# addprocs(5; exeflags="--project")

# @everywhere using GamesOnNetworks
using GamesOnNetworks

const db_filepath = "./sqlite/time_series_saves.sqlite"
const db_store_period = 1
# db_init(db_filepath)
# const sim_group_id = db_insert_sim_group("Example Group Description")


const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])


const graph_params_list = [
    # CompleteParams(),
    # ErdosRenyiParams(5.0),
    SmallWorldParams(5.0, 0.0),
    # ScaleFreeParams(5.0, 2),
    # StochasticBlockModelParams(5.0, 2, 1.0, 0.01)
]

# println("bout to distribute. Worker: ", myid())
println("model list complete..")
for i in eachindex(graph_params_list)
    model = SimModel(Game{3, 3}("Bargaining Game", payoff_matrix), SimParams(100, 10, 0.1), graph_params_list[i], FractiousState(), EquityBehavioral(2))
    show(model)
    db_group_id = db_insert_sim_group(db_filepath, "N=100 $(string(graph_params_list[i])) take 75")
    println(db_group_id)
    simulate(model, db_filepath, db_store_period, db_sim_group_id=db_group_id)
end

# resetprocs()

# first (transition time ~150)
# multipleTimeSeriesPlot(db_filepath, sim_group_ids=[46, 12, 13, 115, 45], labels=["Complete", "Erdos Renyi", "Small-World", "Scale-Free", "Stochastic Block Model"])

# second (transition time ~250)
# multipleTimeSeriesPlot(db_filepath, sim_group_ids=[85, 37, 43, 61, 10], labels=["Complete", "Erdos Renyi", "Small-World", "Scale-Free", "Stochastic Block Model"])
"""
1. C -> 115 !
2. ER -> 510
3. SW -> 155
4. SF -> 125 
5. SBM -> 825
6. ER -> 110 
7. C -> 85
8. SW -> 115 
9. SF -> 425
10. SBM -> 250 (first)
11. C -> 97
12. ER -> 163 (first)
13. SW -> 163 (first)
14. SF -> 150 (first)
15. SBM -> 465
16. C -> 66
17. ER -> 605
18. SW -> 157
19. SF -> 571
20. SBM -> 280

26. C -> 119
27. ER -> 
28. SW -> 
29. SF -> 219 (second)
30. SBM ->

36. C -> 150 (first)
37. ER -> 259 (second)
38. SW -> 232 
39. SF ->
40. SBM -> 396 (first or second?)
41. C -> 
42. ER ->
43. SW -> 246 (second)
44. SF ->
45. SBM -> 168
46. C -> 162
47. SF ->
48. C -> 
49. SF ->

52. C -> 
53. SF ->
"""