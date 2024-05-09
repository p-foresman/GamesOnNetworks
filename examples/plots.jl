using GamesOnNetworks, Plots, SQLite, DataFrames

#quick and dirty way to add graph type
function add_graph_type(db_filepath)
    graph_types = ["complete", "er", "sf", "sw", "sbm"]
    db = SQLite.DB("$db_filepath")
    SQLite.busy_timeout(db, 3000)
    DBInterface.execute(db, "ALTER TABLE graphs
                        RENAME COLUMN graph_type TO graph";)
    DBInterface.execute(db, "ALTER TABLE graphs
                        ADD graph_type TEXT NOT NULL DEFAULT ``";)
    query = DBInterface.execute(db, "SELECT COUNT(*) FROM graphs";)
    df = DataFrame(query)
    for row in 1:df[1, "COUNT(*)"]
        query = DBInterface.execute(db, "SELECT graph_params FROM graphs WHERE graph_id == $row";)
        params = DataFrame(query)[1, "graph_params"]
        for graph_type in graph_types
            if occursin(graph_type, params)
                DBInterface.execute(db, "UPDATE graphs SET graph_type = '$graph_type' WHERE graph_id = $row";)
            end
        end
    end
end


# heatmap
GamesOnNetworks.noise_vs_structure_heatmap_new("./sqlite/slurm_simulation_saves_incomplete.sqlite";
                                    game_id=1,
                                    graph_params_extra=[Dict{Symbol, Any}(:title=>"Erdos-Renyi", :graph_type=>"er"), Dict{Symbol, Any}(:title=>"Small-World (β=0.0)", :graph_type=>"sw", :β=>0.0)],
                                    errors=[0.1, 0.2],
                                    mean_degrees=[3.0, 5.0, 10.0],
                                    number_agents=1000,
                                    memory_length=10,
                                    starting_condition_id=1,
                                    stopping_condition_id=1,
                                    sample_size=4)