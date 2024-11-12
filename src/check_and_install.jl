# Check and install nrlmsise00 Python package
function check_and_install_nrlmsise00()
    try
        @info "loading nrlmsise00."
        return pyimport("nrlmsise00")
    catch e
        @info "loading nrlmsise00 failed. Trying to install nrlmsise00 via pip..."
        if isa(e, PyCall.PyError) && occursin("PyImport_ImportModule", e.msg)
            # Run pip install and capture output
            result = read(`$(PyCall.python) -m pip install nrlmsise00`, String)
            @info "pip install output: $result"

            # Check if installation succeeded
            if occursin("Successfully installed", result)
                @info "nrlmsise00 installed."
                return pyimport("nrlmsise00")
            else
                @error "installation of nrlmsise00 failed. Please check the following output for errors:\n$result"
                rethrow(e)
            end
        else
            @error "installation of nrlmsise00 failed. Please install nrlmsise00 via pip."
            rethrow(e)
        end
    end
end

# Check and install SPICE
function check_and_install_spice_earth_kernel()
    # check if folder "spice_kernels" exists
    kernel_dir = "/home/miklas/.julia/dev/SATORBIT/src/spice_kernels/"
    if !isdir(kernel_dir)
        mkdir(kernel_dir)
    end

    # Get the files in the directory
    files = readdir(kernel_dir)

    # Get the files that ends with combined.ppc
    combined_kernel_files = filter(x -> occursin("combined.bpc", x), files)
    combined_kernel_file = "" # Initialize the variable

    if isempty(combined_kernel_files) # If the file is not found
        try
            @info("Earth SPICE kernel file not found. Downloading the latest earth SPICE kernel file...")
            # Download the file that ends with *combined.bpc* from the website
            url = "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/pck/"

            # Get the list of remote files
            remote_files = get_remote_files(url)
            combined_kernel_file = maximum(remote_files)

            # Download the file
            download(url * combined_kernel_file, joinpath(kernel_dir, combined_kernel_file))
        catch e
            @error("Downloading the latest earth SPICE kernel file failed. Please check the following error message:\n$e")
        end
    else # If the file is found
        combined_kernel_file = combined_kernel_files[1]

        # Get last modified date of the file
        local_last_modified = stat(kernel_dir * combined_kernel_file).mtime

        # Transform to DateTime
        local_last_modified_datetime = unix2datetime(local_last_modified)
        local_last_modified_date = Date(local_last_modified_datetime)

        if today() - local_last_modified_date >= Dates.Day(1) # Load the file if it is older than 1 day
            try
                @info("Download latest earth SPICE kernel file...")

                # Remove the old file
                rm(joinpath(kernel_dir, combined_kernel_file))

                # Download the file that ends with *combined.bpc* from the website
                url = "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/pck/"

                # Get the list of remote files
                remote_files = get_remote_files(url)
                combined_kernel_file = maximum(remote_files)

                # Download the file
                download(url * combined_kernel_file, joinpath(kernel_dir, combined_kernel_file))
            catch e
                @error("Downloading the latest SPICE kernel file failed. Please check the following error message:\n$e")
            end
        end
    end

    # Load SPICE Kernels
    earth_kernel = joinpath(kernel_dir, combined_kernel_file)

    try
        @info "loading earth SPICE kernel."
        furnsh(earth_kernel)
    catch e
        @error("loading earth SPICE kernels failed. Please check the following error message:\n$e")
    end
end

function check_and_install_spice_leapseconds_kernel()
    # check if folder "spice_kernels" exists
    kernel_dir = "/home/miklas/.julia/dev/SATORBIT/src/spice_kernels/"
    if !isdir(kernel_dir)
        mkdir(kernel_dir)
    end

    file_name = "latest_leapseconds.tls"

    if !isfile(joinpath(kernel_dir, file_name))
        try
            @info("Leapseconds kernel file not found. Downloading the latest leapseconds kernel file...")
            url = "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/lsk/"
            download(url * file_name, joinpath(kernel_dir, file_name))
        catch e
            @error("Downloading the latest leapseconds kernel file failed. Please check the following error message:\n$e")
        end
    end

    # Load leapseconds kernel
    leapseconds_kernel = joinpath(kernel_dir, file_name)

    try
        @info "loading leapseconds kernel."
        furnsh(leapseconds_kernel)
    catch e
        @error("loading leapseconds kernel failed. Please check the following error message:\n$e")
    end
end

# Function to get the list of files in the remote directory -> used in check_and_install_spice
function get_remote_files(url::String)
    response = HTTP.get(url)
    if response.status == 200
        return [m.match for m in eachmatch(r"earth_\d+_\d+_\d+_combined\.bpc", String(response.body))]
    else
        error("Could not retrieve file list from the remote directory.")
    end
end


# Check and install space weather data
function check_and_install_spaceweather_historical()
    # Check if space weather data is available
    file_path = joinpath(@__DIR__,"spaceweather/Kp_ap_Ap_SN_F107_since_1932.txt")
    if isfile(file_path)
        try
            # check if space weather is up to date
            todays_date = today()
            file_stat = stat(file_path)
            last_modified = file_stat.mtime
            last_modified_datetime = unix2datetime(last_modified)
            last_modified_date = Date(last_modified_datetime)
            if todays_date - last_modified_date >= Dates.Day(1)
                @info "Historical space weather data is outdated. Trying to update..."
                download("https://kp.gfz-potsdam.de/app/files/Kp_ap_Ap_SN_F107_since_1932.txt", file_path)
                @info "Historical space weather data updated."
            end
            @info "loading historical space weather data."
            return spaceweather_historical(file_path)
        catch e
            @error("loading historical space weather data failed. Please check the following error message:\n$e")
        end
    else
        try
            @info("Historical space weather data not found. Downloading historical space weather data...")
            download("https://kp.gfz-potsdam.de/app/files/Kp_ap_Ap_SN_F107_since_1932.txt", file_path)
            @info("Historical space weather data downloaded.")
            return spaceweather_historical(file_path)
        catch e
            @error("Downloading historical space weather data failed. Please check the following error message:\n$e")
        end
    end
end

function check_and_install_spaceweather_daily_forecast()
    # Check if space weather data is available
    file_path = joinpath(@__DIR__,"spaceweather/45-day-ap-forecast.txt")
    if isfile(file_path)
        try
            # check if space weather is up to date
            todays_date = today()
            file_stat = stat(file_path)
            last_modified = file_stat.mtime
            last_modified_datetime = unix2datetime(last_modified)
            last_modified_date = Date(last_modified_datetime)
            if todays_date - last_modified_date >= Dates.Day(1)
                @info "Daily space weather forecast data is outdated. Trying to update..."
                download("https://services.swpc.noaa.gov/text/45-day-ap-forecast.txt", file_path)
                @info "Daily space weather forecast data updated."
            end
        catch e
            @error("loading daily space weather forecast data failed. Please check the following error message:\n$e")
        end
    else
        try
            @info("Daily space weather forecast data not found. Downloading data...")
            download("https://services.swpc.noaa.gov/text/45-day-ap-forecast.txt", file_path)
        catch e
            @error("Downloading daily space weather forecast data failed. Please check the following error message:\n$e")
        end
    end

    # Load the space weather daily forecast data
    @info("loading daily space weather forecast data.")
    return spaceweather_daily_forecast(file_path)
end

function check_and_install_spaceweather_monthly_forecast()
    # Get the current loaded space weather data
    directory_path = joinpath(@__DIR__,"spaceweather/")
    files = readdir(directory_path)
    file_name_nbr = findfirst(f -> endswith(f, "f10-prd.txt"), files)

    if file_name_nbr === nothing # If the file is not found
        todays_date = today()
        current_year = Dates.year(todays_date)
        current_month = Dates.month(todays_date)
        # Download the most recent space weather monthly forecast data
        try
            # Download the most recent space weather monthly forecast data
            @info("Downloading most recent monthly space weather forecast data...")
            month_str =lowercase(Dates.monthname(todays_date)[1:3])
            year_str = string(current_year)
            file_name = month_str * year_str * "f10-prd.txt"

            download_path = "https://www.nasa.gov/wp-content/uploads/" * year_str * "/" * string(current_month) * "/" * file_name
            download(download_path, joinpath(directory_path, file_name))
        catch e
            @error("Downloading most recent monthly space weather forecast data failed. Please check the following error message:\n$e")
        end
    else # Check if it is the most recent one
        file_name = files[file_name_nbr]
        month_str = file_name[1:3]
        year_str = file_name[4:7]

        month_map = Dict(
            "jan" => 1, "feb" => 2, "mar" => 3, "apr" => 4,
            "may" => 5, "jun" => 6, "jul" => 7, "aug" => 8,
            "sep" => 9, "oct" => 10, "nov" => 11, "dec" => 12
        )

        month = month_map[month_str]
        year = parse(Int, year_str)
        todays_date = today()
        current_year = Dates.year(todays_date)
        current_month = Dates.month(todays_date)

        if year < current_year || (year == current_year && month < current_month)
            try
                # Delete the old file
                rm(joinpath(directory_path, file_name))
                # Download the most recent space weather monthly forecast data
                @info("Downloading most recent monthly space weather forecast data...")
                file_name = month_str * year_str * "f10-prd.txt"

                download_path = "https://www.nasa.gov/wp-content/uploads/" * string(current_year) * "/" * string(current_month) * "/" * file_name
                download(download_path, joinpath(directory_path, file_name))
            catch e
                @error("Downloading most recent monthly space weather forecast data failed. Please check the following error message:\n$e")
            end
        end
    end

    # Load the space weather monthly forecast data
    @info("loading monthly space weather forecast data.")
    return spaceweather_monthly_forecast(joinpath(directory_path, file_name))
end