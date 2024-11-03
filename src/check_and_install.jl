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
            @info "loading spaceweather data."
            return spaceweather(file_path)
        catch e
            @error("loading spaceweather data failed.")
        end
    else
        @error("Spaceweather data is missing. File not found: $file_path")
    end
end