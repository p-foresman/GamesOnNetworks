#these initializations may be varied
number_agents = 10
matches_per_period = floor(number_agents / 2)
memory_length = 10
error = 0.10
tag_proportion = 1.0 #1.0 for effectively "no tags" (all agents get tag1)
sufficient_equity = (1 - error) * memory_length #can you instantiate this with struct function?
#number_periods = 80
tag1 = "red" #not used yet
tag2 = "blue" #not used yet
m_init = "fractious" #specifies initialization state
iterationParam = :memorylength #can be :memorylength or :numberagents
iterator = 10:1:10 #7:3:19 #determines the values of the indepent variable (right now set for one iteration (memory lenght 10))
error_list = [0.1]
averager = 5

params = SimParams(number_agents,
                memory_length,
                error,
                matches_per_period,
                tag_proportion,
                sufficient_equity,
                tag1,
                tag2,
                m_init,
                iterationParam,
                iterator,
                error_list,
                averager)