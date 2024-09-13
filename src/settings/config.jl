using TOML
import Pkg

const default_config_path = joinpath(@__DIR__, "default_config.toml")
const user_config_path = "GamesOnNetworks.toml"


struct Settings
    data::Dict{String, Any} #Base.ImmutableDict #contains the whole parsed .toml config
    db_type::String
    db_name::String
    db_info::Dict{String, String} #Base.ImmutableDict{String, String}
    # db_insert::Function
end

function Settings(settings::Dict{String, Any})
    @assert haskey(settings, "database") "config file must have a [database] table"
    @assert settings["database"] isa Dict "[database] must be a table (Dict)"
    @assert haskey(settings["database"], "default") "config file must have a 'default' database path in the [database] table using dot notation of the form \"db_type.db_name\""
    @assert settings["database"]["default"] isa String "the denoted default database must be a String"

    parsed_db_key_path = split(settings["database"]["default"], ".")
    @assert length(parsed_db_key_path) == 2 "'default' database path must be of the form \"db_type.db_name\""

    db_type::String, db_name::String = parsed_db_key_path
    @assert db_type == "sqlite" || db_type == "postgres" "'db_type in the 'default' database path (of the form \"db_type.db_name\") must be 'sqlite' or 'postgres'"
    @assert haskey(settings["database"], db_type) "config file does not contain table [database.$db_type]"
    @assert settings["database"][db_type] isa Dict "[database.db_type] must be a table (Dict)"
    @assert haskey(settings["database"][db_type], db_name) "config file does not contain table [database.$db_type.$db_name]"
    @assert settings["database"][db_type][db_name] isa Dict "[database.db_type.db_name] must be a table (Dict)"

    db_info = settings["database"][db_type][db_name]
    if db_type == "sqlite"
        @assert haskey(db_info, "path") "database config table [database.sqlite.$db_name] must contain 'path' variable"
        @assert db_info["path"] isa String "database config table [database.sqlite.$db_name] 'path' variable must be a String"
        # db_insert = db_insert_game
    else #db_type == "postgres"
        # db_insert = db_insert_graph
    end

    return Settings(settings, db_type, db_name, db_info)#, db_insert)
end

function Settings(config_path::String)
    @assert last(split(config_path, ".")) == "toml" "config file be .toml"
    # settings = TOML.parsefile(config_path)
    return Settings(TOML.parsefile(config_path))
end



"""
    get_default_config(;overwrite::bool=false)

Get the default GamesOnNetworks.toml config file. CAUTION: setting overwrite=true will replace your current GamesOnNetworks.toml file.
"""
function get_default_config(;overwrite::Bool=false)
    cp(default_config_path, user_config_path, force=overwrite)
    chmod(user_config_path, 0o777) #make sure the file is writable
end



"""
    GamesOnNetworks.configure()

Load the GamesOnNetworks.toml config file to be used in the GamesOnNetworks package
"""
function configure()
    if isfile(user_config_path)
        #load the user's settings config
        println("configuring GamesOnNetworks using GamesOnNetworks.toml...")
        GamesOnNetworks.SETTINGS = Settings(user_config_path)

    else
        #load the default config which come with the package
        println("configuring using the default config...")
        GamesOnNetworks.SETTINGS = Settings(default_config_path)
    
        #give the user the default .toml file to customize if desired
        get_default_config()
    end

    #load database functions (different for different database types)
    local_src_path = chop(@__DIR__, tail=8)
    include(joinpath(local_src_path, "database/$(SETTINGS.db_type)/database_api.jl"))
    include(joinpath(local_src_path, "database/$(SETTINGS.db_type)/sql.jl"))

    #initialize the database
    Base.invokelatest(db_init)
end
