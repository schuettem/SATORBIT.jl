# Check and install nrlmsise00 Python package
function check_and_install_nrlmsise00()
    try
        @info "loading nrlmsise00"
        return pyimport("nrlmsise00")
    catch e
        if isa(e, PyCall.PyError) && occursin("PyImport_ImportModule", e.msg)
            @info "start installing nrlmsise00 via pip..."

            # Run pip install and capture output
            result = read(`$(PyCall.python) -m pip install nrlmsise00`, String)
            @info "pip install output: $result"

            # Check if installation succeeded
            if occursin("Successfully installed", result)
                @info "installing nrlmsise00 finished."
                return pyimport("nrlmsise00")
            else
                @error "installing nrlmsise00 failed. Please check the following output for errors:\n$result"
                rethrow(e)
            end
        else
            @info "installing of nrlmsise00 failed. Please install nrlmsise00 via pip."
            rethrow(e)
        end
    end
end

# Check and install SPICE
function check_and_install_spice(leapseconds_kernel, earth_kernel)
    # Load SPICE Kernels
    if isfile(leapseconds_kernel) && isfile(earth_kernel)
        @info "loading SPICE kernels..."
        furnsh(leapseconds_kernel)
        furnsh(earth_kernel)
        @info "loading SPICE kernels finished."
    else
        @error("One or more SPICE kernel files are missing.")
    end
end