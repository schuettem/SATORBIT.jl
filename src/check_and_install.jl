# Check if HWM14 is installed, if not install it from GitHub
function check_and_install_hwm14()
    try
        @info "loading HWM14 package"
        @eval using HWM14
    catch e
        @info "loading HWM14 package failed. Installing HWM14 from GitHub..."
        if isa(e, ArgumentError) && occursin("HWM14", e.msg)
            Pkg.add(url="git@github.com:schuettem/HWM14.git")
            @eval using HWM14
        else
            @info "installing of HWM14 package failed. Please install HWM14 from GitHub."
            rethrow(e)
        end
    end
end

# Check and install nrlmsise00 Python package
function check_and_install_nrlmsise00()
    try
        @info "loading nrlmsise00"
        return pyimport("nrlmsise00")
    catch e
        @info "loading of nrlmsise00 failed. Installing nrlmsise00 via pip..."
        if isa(e, PyError) && occursin("ModuleNotFoundError", e.msg)
            run(`$(PyCall.python) -m pip install nrlmsise00`)
            return pyimport("nrlmsise00")
        else
            @info "installing of nrlmsise00 failed. Please install nrlmsise00 via pip."
            rethrow(e)
        end
    end
end

function check_and_install_spice()
    # The SPICE kernels used in this script are provided by the NASA Navigation and Ancillary Information Facility (NAIF).
    # Data Source: NAIF Generic Kernels (https://naif.jpl.nasa.gov/naif/data_generic.html).
    leapseconds_kernel = joinpath(@__DIR__, "spice_kernels/latest_leapseconds.tls")
    earth_kernel = joinpath(@__DIR__, "spice_kernels/earth_620120_240827.bpc") # Earth orientation history kernel

    # Load SPICE Kernels
    if isfile(leapseconds_kernel) && isfile(earth_kernel)
        furnsh(leapseconds_kernel)
        furnsh(earth_kernel)
    else
        error("One or more SPICE kernel files are missing.")
    end
end
