using TOML

const default_config_path = joinpath(@__DIR__, "default_config.toml")
const user_config_path = "GamesOnNetworks.toml"


"""
    get_default_config(;overwrite::bool=false)

Get the default GamesOnNetworks.toml config file. CAUTION: setting overwrite=true will replace your current GamesOnNetworks.toml file.
"""
function get_default_config(;overwrite::Bool=false)
    cp(default_config_path, user_config_path, force=overwrite)
end

"""
    GamesOnNetworks.configure(config_path::string)

Load a custom .toml config file to be used in the GamesOnNetworks package
"""
function configure(config_path::String)
    @assert last(split(config_path, ".")) == "toml" "config file be .toml"

    settings = TOML.parsefile(config_path)
    @assert haskey(settings, "database") "config file must have a [database] table"
    @assert settings["database"] isa Dict "[database] must be a table (Dict)"
    @assert haskey(settings["database"], "default") "config file must have a 'default' database path in the [database] table using dot notation of the form \"db_type.db_name\""

    parsed_db_key_path = split(settings["database"]["default"], ".")
    @assert length(parsed_db_key_path) == 2 "'default' database path must be of the form \"db_type.db_name\""

    db_type, db_name = parsed_db_key_path
    @assert db_type == "sqlite" || db_type == "postgres" "'db_type in the 'default' database path (of the form \"db_type.db_name\") must be 'sqlite' or 'postgres'"
    @assert haskey(settings["database"], db_type) "config file does not contain table [database.$db_type]"
    @assert settings["database"][db_type] isa Dict "[database.db_type] must be a table (Dict)"
    @assert haskey(settings["database"][db_type], db_name) "config file does not contain table [database.$db_type.$db_name]"
    @assert settings["database"][db_type][db_name] isa Dict "[database.db_type.db_name] must be a table (Dict)"

    db_info = settings["database"][db_type][db_name]
    if db_type == "sqlite"
        @assert haskey(db_info, "path") "database config table [database.sqlite.$db_name] must contain 'path' variable"
        @assert db_info["path"] isa String "database config table [database.sqlite.$db_name] 'path' variable must be a String"
    else #db_type == "postgres"

    end

    GamesOnNetworks.SETTINGS = settings
    GamesOnNetworks.DB_TYPE = db_type
    GamesOnNetworks.DB_NAME = db_name
    GamesOnNetworks.DB_INFO = db_info

    if DB_TYPE == "sqlite"
        db_init(DB_INFO["path"])
    elseif DB_TYPE == "postgres"
        #add in init_method here
    end
end

"""
    GamesOnNetworks.configure()

Load the GamesOnNetworks.toml config file to be used in the GamesOnNetworks package
"""
function configure()
    if isfile(user_config_path)
        #load the user's settings config
        configure(user_config_path)
    else
        #load the default config which come with the package
        configure(default_config_path)
    
        #give the user the default .toml file to customize if desired
        get_default_config()
    end
end


#configure on pre-compilation
configure()