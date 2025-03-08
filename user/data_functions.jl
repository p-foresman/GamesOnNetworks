function get_data(state::State)
    HML = [0, 0, 0]
    for agent in GamesOnNetworks.agents(state)
        if !GamesOnNetworks.ishermit(agent)
            HML[GamesOnNetworks.rational_choice(agent)] += 1
        end
    end
    total_agents = sum(HML)
    return Dict{String, Float64}(
        "H" => HML[1] / total_agents,
        "M" => HML[2] / total_agents,
        "L" => HML[3] / total_agents,
    )
end