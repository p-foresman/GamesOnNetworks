"""
Example file for a simple, one-off simulation
"""

"""
Step 1: Load the main "GamesOnNetworks" module onto all processes
"""
using GamesOnNetworks


"""
Step 2: Define a database filepath if you want simulation data stored (not required to run a simulation)
    -an sqlite database file should be initiallized prior to executing this file, but can be initialized here as follows
        -db can be initialized with initDB("./examle_database_filepath.sqlite"), which will create the file and the proper database schema
        -simulation "groups" need to be created manually as well using the insertSimGroup("group description") function
"""
const db_filepath = "./examle_database_filepath.sqlite"
db_init(db_filepath) #optional
const sim_group_id = db_insert_sim_group("Example Group Description") #optional


"""
Step 3: Set up the model that you want to simulate
    -this setup could be defined in a separate script if desired
"""
const payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                            (0, 0) (50, 50) (50, 30);
                                            (30, 70) (30, 50) (30, 30)])

const model = SimModel(Game{3, 3}("Bargaining Game", payoff_matrix), 
                        SimParams(10, 10, 0.1),
                        CompleteParams(),
                        FractiousState(),
                        EquityBehavioral(2))


"""
Step 4: Run simulation on the constructed model
    -a variety of simulation options are shown
"""
simulate(model) #simple simulation. returns periods elapsed
simulate(model, db_filepath) #add db_filepath to store simulation data in the sqlite file
simulate(model, db_filepath, 100) #add a db store period to store simulation data periodically