using TOML

"""
    load_settings(toml_path::string)

Load custom configuration settings from a .toml file to be used in GamesOnNetworks
"""
function load_settings(toml_path::String)
    GamesOnNetworks.SETTINGS = TOML.parsefile(toml_path)
    GamesOnNetworks.DB_TYPE, GamesOnNetworks.DB_NAME = split(SETTINGS["database"]["default"], ".")
    GamesOnNetworks.DB_INFO = SETTINGS["database"][DB_TYPE][DB_NAME]

    if DB_TYPE == "sqlite"
        db_init(DB_INFO["path"])
    elseif DB_TYPE == "postgres"
        #add in init_method here
    end
end



if isfile("./settings.toml")
    #load the user's settings config
    load_settings("./settings.toml")
else
    #load the default settings which come with the package
    load_settings("src/settings/default_settings.toml")

    #give the user the default .toml file to customize if desired
    cp("src/settings/default_settings.toml", "settings.toml")
end