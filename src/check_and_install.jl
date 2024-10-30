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