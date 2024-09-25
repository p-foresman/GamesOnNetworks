using TOML
import Pkg

const default_config_path = joinpath(@__DIR__, "default_config.toml")
const user_config_path = "GamesOnNetworks.toml"


# abstract type Database end

# struct PostgresDB <: Database
#     name::String
#     user::String
#     host::String
#     port::String
#     password::String
# end

# struct SQLiteDB <: Database
#     name::String
#     filepath::String
# end

# db_type(database::SQLiteDB) = "sqlite"
# db_type(database::PostgresDB) = "postgres"

struct Settings
    data::Dict{String, Any} #Base.ImmutableDict #contains the whole parsed .toml config
    use_seed::Bool
    # use_distributed::Bool
    procs::Int
    database::Union{Database, Nothing} #if nothing, not using database
    # db_type::String
    # db_name::String
    # db_info::Dict{String, String} #Base.ImmutableDict{String, String}
    # db_insert::Function
end

function Settings(settings::Dict{String, Any})
    @assert haskey(settings, "use_seed") "config file must have a 'use_seed' variable"
    use_seed = settings["use_seed"]
    @assert use_seed isa Bool "'use_seed' value must be a Bool"


    # @assert haskey(settings, "use_distributed") "config file must have a 'use_distributed' variable"
    # use_distributed = settings["use_distributed"]
    # @assert use_distributed isa Bool "'use_distributed' value must be a Bool"

    @assert haskey(settings, "processes") "config file must have a 'processes' variable"
    procs = settings["processes"]
    @assert procs isa Int && procs >= 1 "'processes' value must be a positive Int (>=1)"

    @assert haskey(settings, "databases") "config file must have a [databases] table"
    databases = settings["databases"]
    database = nothing #selected database
    @assert databases isa Dict "[databases] must be a table (Dict)"
    @assert haskey(databases, "selected") "config file must have a 'selected' database path in the [databases] table using dot notation of the form \"db_type.db_name\" OR an empty string if not using a database"
    selected_db = databases["selected"]
    @assert selected_db isa String "the denoted default database must be a String (can be an empty string if not using a database)"

    #if selected_db exists, must validate selected database. Otherwise, not using database
    if !isempty(selected_db)
        parsed_db_key_path = split(selected_db, ".")
        @assert length(parsed_db_key_path) == 2 "'selected' database path must be of the form \"db_type.db_name\""
    
        db_type::String, db_name::String = parsed_db_key_path
        @assert db_type == "sqlite" || db_type == "postgres" "'db_type in the 'selected' database path (of the form \"db_type.db_name\") must be 'sqlite' or 'postgres'"
        @assert haskey(databases, db_type) "config file does not contain table [databases.$db_type]"
        @assert databases[db_type] isa Dict "[databases.$db_type] must be a table (Dict)"
        @assert haskey(databases[db_type], db_name) "config file does not contain table [databases.$db_type.$db_name]"
        @assert databases[db_type][db_name] isa Dict "[databases.$db_type.$db_name] must be a table (Dict)"
    
        db_info = databases[db_type][db_name]
        if db_type == "sqlite"
            @assert haskey(db_info, "path") "database config table [database.sqlite.$db_name] must contain 'path' variable"
            @assert db_info["path"] isa String "database config table [database.sqlite.$db_name] 'path' variable must be a String"
            database = SQLiteDB(db_name, db_info["path"])
        elseif db_type == "postgres"
            @assert haskey(db_info, "user") "database config table [database.postgres.$db_name] must contain 'user' variable"
            @assert haskey(db_info, "host") "database config table [database.postgres.$db_name] must contain 'host' variable"
            @assert haskey(db_info, "port") "database config table [database.postgres.$db_name] must contain 'port' variable"
            @assert haskey(db_info, "password") "database config table [database.postgres.$db_name] must contain 'password' variable"
            database = PostgresDB(db_name, db_info["user"], db_info["host"], db_info["port"], db_info["password"])
        end
    end

    return Settings(settings, use_seed, procs, database)
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
        myid() == 1 && println("configuring GamesOnNetworks using GamesOnNetworks.toml")
        GamesOnNetworks.SETTINGS = Settings(user_config_path)

    else
        #load the default config which come with the package
        myid() == 1 && println("configuring using the default config")
        GamesOnNetworks.SETTINGS = Settings(default_config_path)
    
        #give the user the default .toml file to customize if desired
        myid() == 1 && get_default_config()
    end

    if myid() == 1
        if !isnothing(SETTINGS.database)
            #initialize the database
            print("initializing databse [$(db_type(SETTINGS.database)).$(SETTINGS.database.name)]... ")
            # out = stdout
            # redirect_stdout(devnull)
            @suppress db_init() #suppress the stdout stream
            # redirect_stdout(out)
            println("database initialized")
        end

        resetprocs() #resets the process count to 1 for proper reconfigure
        if SETTINGS.procs > 1
            #initialize distributed processes with GamesOnNetworks available in their individual scopes
            print("adding $(SETTINGS.procs) distributed processes... ")
            procs = addprocs(SETTINGS.procs)
            project_path = splitdir(Pkg.project().path)[1]
            @everywhere procs begin
                eval(quote
                    # include(joinpath(dirname(@__DIR__), "GamesOnNetworks.jl")) # this method errors on other local projects since the project environment doesn't contain all of the dependencies (Graphs, Plots, etc)
                    # using .GamesOnNetworks
                    import Pkg
                    Pkg.activate($$project_path; io=devnull) #must activate the local project environment to gain access to the GamesOnNetworks package
                    using GamesOnNetworks #will call __init__() on startup for these processes which will configure all processes internally
                end)
            end
            println("$(SETTINGS.procs) processes initialized")
        else
            println("1 process initialized")
        end
        println("configuration complete")
    end
end