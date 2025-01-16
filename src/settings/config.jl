using TOML

const project_dirpath() = dirname(Base.active_project()) #these must be functions so they don't store the paths where GamesOnNetworks is precompiled
const default_toml_path() = joinpath(@__DIR__, "default_config.toml")
const user_toml_path() = joinpath(project_dirpath(), "GamesOnNetworks.toml")


# abstract type Database end

# struct Database.PostgresInfo <: Database
#     name::String
#     user::String
#     host::String
#     port::String
#     password::String
# end

# struct Database.SQLiteInfo <: Database
#     name::String
#     filepath::String
# end

# db_type(database::Database.SQLiteInfo) = "sqlite"
# db_type(database::Database.PostgresInfo) = "postgres"

struct Checkpoint
    database::Database.DBInfo #if SETTINGS.database is nothing, this doesn't matter. otherwise, this is used to set an optional alternative database to checkpoint into
    # timeout::Int
end

struct Settings
    data::Dict{String, Any} #Base.ImmutableDict #contains the whole parsed .toml config
    use_seed::Bool
    random_seed::Int
    # use_distributed::Bool
    procs::Int
    timeout::Int
    database::Union{Database.DBInfo, Nothing} #if nothing, not using database
    checkpoint::Bool
    checkpoint_exit_code::Int
    figure_dirpath::String
    # data_script::Union{Nothing, String}
end

function Settings(settings::Dict{String, Any})
    @assert haskey(settings, "use_seed") "config file must have a 'use_seed' variable"
    use_seed = settings["use_seed"]
    @assert use_seed isa Bool "'use_seed' value must be a Bool"

    @assert haskey(settings, "random_seed") "config file must have a 'random_seed' variable"
    random_seed = settings["random_seed"]
    @assert random_seed isa Int && random_seed >= 0 "'random_seed' value must be an Int (>= 0)"


    # @assert haskey(settings, "use_distributed") "config file must have a 'use_distributed' variable"
    # use_distributed = settings["use_distributed"]
    # @assert use_distributed isa Bool "'use_distributed' value must be a Bool"

    @assert haskey(settings, "processes") "config file must have a 'processes' variable"
    procs = settings["processes"]
    @assert procs isa Int && procs >= 1 "'processes' value must be a positive Int (>=1)"

    @assert haskey(settings, "timeout") "config file must have a 'timeout' variable"
    timeout = settings["timeout"]
    @assert timeout isa Int && timeout >= 0 "'timeout' value must be a positive Int (>=1) OR 0 (denoting no timeout)"

    @assert haskey(settings, "figure_dirpath") "config file must have a 'figure_dirpath' variable"
    figure_dirpath = settings["figure_dirpath"]
    @assert figure_dirpath isa String "the 'figure_dirpath' variable must be a String (empty string for project root)"
    figure_dirpath = normpath(joinpath(project_dirpath(), figure_dirpath))

    @assert haskey(settings, "databases") "config file must have a [databases] table"
    databases = settings["databases"]
    @assert databases isa Dict "[databases] must be a table (Dict)"
    @assert haskey(databases, "selected") "config file must have a 'selected' database path in the [databases] table using dot notation of the form \"db_type.db_name\" OR an empty string if not using a database"
    selected_db = databases["selected"]
    @assert selected_db isa String "the denoted default database must be a String (can be an empty string if not using a database)"
    
    @assert haskey(databases, "checkpoint") "config file must have a 'checkpoint' boolean variable. This field's value only matters if a database is selected"
    checkpoint = databases["checkpoint"]
    @assert checkpoint isa Bool "'checkpoint' value must be a Bool"
    @assert haskey(databases, "checkpoint_exit_code") "config file must have a 'checkpoint_exit_code' positive integer variable"
    checkpoint_exit_code = databases["checkpoint_exit_code"]
    @assert checkpoint_exit_code isa Int && checkpoint_exit_code >= 0 "'checkpoint_exit_code' value must be a positive Int (>=1) OR 0 (denoting no exit)"
    # @assert haskey(databases, "checkpoint_database") "config file must have a 'checkpoint_database' database path in the [databases] table using dot notation of the form \"db_type.db_name\" OR an empty string to use main selected database"

    # @assert haskey(databases, "data_script") "config file must have a 'data_script' variable in the [databases] table specifying the path to a data loading script to be loaded on database initialization OR an empty string if no data loading is required"
    # data_script = databases["data_script"]
    # @assert data_script isa String "the 'data_script' variable must be a String (can be an empty string if data loading isn't required)"
    # if !isempty(data_script)
    #     data_script = normpath(joinpath(project_dirpath, data_script))
    #     @assert isfile(data_script)
    # else
    #     data_script = nothing
    # end


    #if selected_db exists, must validate selected database. Otherwise, not using database
    database = nothing #selected database
    # checkpoint = nothing #checkpoint database
    if !isempty(selected_db)
        database = validate_database(databases, "selected", selected_db)



        # if databases["checkpoint"]
        #     checkpoint_db = databases["checkpoint_database"]
        #     if isempty(checkpoint_db)
        #         checkpoint = Checkpoint(database)
        #     else
        #        checkpoint = Checkpoint(validate_database(databases, "checkpoint_database", checkpoint_db))
        #     end
        # end
    end

    return Settings(settings, use_seed, random_seed, procs, timeout, database, checkpoint, checkpoint_exit_code, figure_dirpath)
end

function Settings(toml_path::String)
    @assert last(split(toml_path, ".")) == "toml" "config file be .toml"
    # settings = TOML.parsefile(toml_path)
    return Settings(TOML.parsefile(toml_path))
end

function validate_database(databases::Dict, field::String, db_path::String)
    parsed_db_key_path = split(db_path, ".")
    @assert length(parsed_db_key_path) == 2 "'$field' database path must be of the form \"db_type.db_name\""

    db_type::String, db_name::String = parsed_db_key_path
    @assert db_type == "sqlite" || db_type == "postgres" "'db_type in the '$field' database path (of the form \"db_type.db_name\") must be 'sqlite' or 'postgres'"
    @assert haskey(databases, db_type) "config file does not contain table [databases.$db_type]"
    @assert databases[db_type] isa Dict "[databases.$db_type] must be a table (Dict)"
    @assert haskey(databases[db_type], db_name) "config file does not contain table [databases.$db_type.$db_name]"
    @assert databases[db_type][db_name] isa Dict "[databases.$db_type.$db_name] must be a table (Dict)"

    db_info = databases[db_type][db_name]
    if db_type == "sqlite"
        @assert haskey(db_info, "path") "database config table [database.sqlite.$db_name] must contain 'path' variable"
        @assert db_info["path"] isa String "database config table [database.sqlite.$db_name] 'path' variable must be a String"
        return Database.SQLiteInfo(db_name, normpath(joinpath(project_dirpath(), db_info["path"]))) #NOTE: could use pwd() here to create database in the current directory (more freedom, more potential bugs)
    elseif db_type == "postgres"
        @assert haskey(db_info, "user") "database config table [database.postgres.$db_name] must contain 'user' variable"
        @assert haskey(db_info, "host") "database config table [database.postgres.$db_name] must contain 'host' variable"
        @assert haskey(db_info, "port") "database config table [database.postgres.$db_name] must contain 'port' variable"
        @assert haskey(db_info, "password") "database config table [database.postgres.$db_name] must contain 'password' variable"
        return Database.PostgresInfo(db_name, db_info["user"], db_info["host"], db_info["port"], db_info["password"])
    end
end



"""
    get_default_config(;overwrite::bool=false)

Get the default GamesOnNetworks.toml config file. CAUTION: setting overwrite=true will replace your current GamesOnNetworks.toml file.
"""
function get_default_config(;overwrite::Bool=false)
    cp(default_toml_path(), user_toml_path(), force=overwrite)
    chmod(user_toml_path(), 0o777) #make sure the file is writable
    println("default config file added to project directory as 'GamesOnNetworks.toml'. Use this file to configure package settings.")
end


"""
    GamesOnNetworks.configure()

Load the GamesOnNetworks.toml config file to be used in the GamesOnNetworks package
"""
function configure(toml_path::String="")
    # println(project_dirpath())
    # println(default_toml_path())
    # println(user_toml_path())
    if isempty(toml_path) #if no .toml filepath is provided, try to get the GamesOnNetworks.toml in the project directory. If this doesn't exist, use the default_config.toml, which will be generated within the project directory as GamesOnNetworks.toml
        if isfile(user_toml_path())
            #load the user's settings config
            myid() == 1 && println("configuring GamesOnNetworks using GamesOnNetworks.toml")
            toml_path = user_toml_path()
        else
            #load the default config which come with the package
            myid() == 1 && println("configuring using the default config")
            toml_path = default_toml_path()
        
            #give the user the default .toml file to customize if desired
            myid() == 1 && get_default_config()
        end
    else
        @assert (splitext(toml_path)[2] == ".toml") "toml_path provided does not have a .toml extension"
        toml_path = abspath(toml_path)
    end

    #create the global SETTINGS variable
    global SETTINGS = Settings(toml_path)


    if myid() == 1
        if !isnothing(SETTINGS.database)
            #initialize the database
            print("initializing databse [$(Database.type(SETTINGS.database)).$(SETTINGS.database.name)]... ")
            # out = stdout
            # redirect_stdout(devnull)
            Database.db_init(SETTINGS.database) #;data_script=SETTINGS.data_script) #suppress the stdout stream
            #NOTE: add a "state" database table which stores db info like 'initialized' (if initialized is true, dont need to rerun initialization)
            # include()
            if SETTINGS.database isa Database.SQLiteInfo
                println("SQLite database file initialized at $(SETTINGS.database.filepath)")
            else
                println("PostgreSQL database initialized")
            end

            # if !isnothing(SETTINGS.checkpoint) && SETTINGS.checkpoint.database != SETTINGS.database
            #     print("initializing checkpoint databse [$(db_type(SETTINGS.checkpoint.database)).$(SETTINGS.checkpoint.database.name)]... ")

            #     db_init(SETTINGS.checkpoint.database)

            #     if SETTINGS.checkpoint.database isa Database.SQLiteInfo
            #         println("SQLite database file initialized at $(SETTINGS.checkpoint.database.filepath)")
            #     else
            #         println("PostgreSQL database initialized")
            #     end
            # end
        end

        resetprocs() #resets the process count to 1 for proper reconfigure
        if SETTINGS.procs > 1 #|| SETTINGS.timeout > 0 #if the timeout is active, need to add a process for the timer to run on
            #initialize distributed processes with GamesOnNetworks available in their individual scopes
            print("initializing $(SETTINGS.procs) distributed processes... ")
            procs = addprocs(SETTINGS.procs)
            @everywhere procs begin
                eval(quote
                    # include(joinpath(dirname(@__DIR__), "GamesOnNetworks.jl")) # this method errors on other local projects since the project environment doesn't contain all of the dependencies (Graphs, Plots, etc)
                    # using .GamesOnNetworks
                    import Pkg
                    Pkg.activate($$(project_dirpath()); io=devnull) #must activate the local project environment to gain access to the GamesOnNetworks package
                    using GamesOnNetworks #will call __init__() on startup for these processes which will configure all processes internally
                end)
            end

            #define user-defined starting and stopping conditions on all workers (only matters if user reconfigures processes with GamesOnNetworks.configure())
            #NOTE: this seems sketch but is working fine for now
            for fn in _starting_condition_registry
                # @startingcondition eval($fn)
                @everywhere eval($fn)
            end
            for fn in _stopping_condition_registry
                # @stoppingcondition eval($fn)
                @everywhere eval($fn)
            end
        end
        println("$(SETTINGS.procs) $(SETTINGS.procs > 1 ? "processes" : "process") initialized")

        if myid() == 1
            mkpath(SETTINGS.figure_dirpath)
            println("figure directory initialized at $(SETTINGS.figure_dirpath)")
        end

        println("configuration complete")
    end
end