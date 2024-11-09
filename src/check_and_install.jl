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
function check_and_install_spice(leapseconds_kernel, earth_kernel)
    # Load SPICE Kernels
    if isfile(leapseconds_kernel) && isfile(earth_kernel)
        try
            @info "loading SPICE kernels."
            furnsh(leapseconds_kernel)
            furnsh(earth_kernel)
        catch e
            @error("loading SPICE kernels failed.")
        end
    else
        @error("One or more SPICE kernel files are missing.")
    end
end

# Check and install spaceweather data
function check_and_install_spaceweather()
    # Check if spaceweather data is available
    file_path = joinpath(@__DIR__,"spaceweather/Kp_ap_Ap_SN_F107_since_1932.txt")
    if isfile(file_path)
        try
            # check if spaceweather is up to date
            todays_date = today()
            file_stat = stat(file_path)
            last_modified = file_stat.mtime
            last_modified_datetime = unix2datetime(last_modified)
            last_modified_date = Date(last_modified_datetime)
            if todays_date - last_modified_date > Dates.Day(1)
                @info "Spaceweather data is outdated. Trying to update spaceweather data..."
                download("https://kp.gfz-potsdam.de/app/files/Kp_ap_Ap_SN_F107_since_1932.txt", file_path)
                @info "Spaceweather data updated."
            end
            @info "loading spaceweather data."
            return spaceweather(file_path)
        catch e
            @error("loading spaceweather data failed.")
        end
    else
        try
            @info("Spaceweather data not found. Downloading spaceweather data...")
            download("https://kp.gfz-potsdam.de/app/files/Kp_ap_Ap_SN_F107_since_1932.txt", file_path)
            @info("Spaceweather data downloaded.")
            return spaceweather(file_path)
        catch e
            @error("Downloading spaceweather data failed.")
        end
    end
end

function check_and_install_spaceweather_forecast()
    # Check if spaceweather data is available
    file_path = joinpath(@__DIR__,"spaceweather/45-day-ap-forecast.txt")
    if isfile(file_path)
        try
            # check if spaceweather is up to date
            todays_date = today()
            file_stat = stat(file_path)
            last_modified = file_stat.mtime
            last_modified_datetime = unix2datetime(last_modified)
            last_modified_date = Date(last_modified_datetime)
            if todays_date - last_modified_date > Dates.Day(1)
                @info "Spaceweather forecast data is outdated. Trying to update spaceweather data..."
                download("https://services.swpc.noaa.gov/text/45-day-ap-forecast.txt", file_path)
                @info "Spaceweather forecast data updated."
            end
            @info "loading spaceweather forecast data."
            return spaceweather_forecast(file_path)
        catch e
            @error("loading spaceweather forecast data failed.")
        end
    else
        try
            @info("Spaceweather forecast data not found. Downloading spaceweather forecast data...")
            download("https://services.swpc.noaa.gov/text/45-day-ap-forecast.txt", file_path)
            @info("Spaceweather forecast data downloaded.")
            return spaceweather_forecast(file_path)
        catch e
            @error("Downloading spaceweather forecast data failed.")
        end
    end
end