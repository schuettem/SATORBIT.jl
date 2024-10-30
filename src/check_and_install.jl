# Check and install nrlmsise00 Python package
function check_and_install_nrlmsise00()
    try
        @info "loading nrlmsise00"
        return pyimport("nrlmsise00")
    catch e
        if isa(e, PyCall.PyError) && occursin("PyImport_ImportModule", e.msg)
            # Capture the output of the pip install command
            result = run(`$(PyCall.python) -m pip install nrlmsise00`, wait=false)

            # Add a short delay to allow the process to start
            sleep(2)

            # Check if the process is still running
            if isopen(result)
                @info "pip install is still running..."
                wait(result)
            end

            # Check the exit code of the process
            if result.exitcode == 0
                @info "installing nrlmsise00 finished."
                return pyimport("nrlmsise00")
            else
                @info "installing nrlmsise00 failed with exit code $(result.exitcode). Please install nrlmsise00 via pip."
                rethrow(e)
            end
        else
            @info "installing of nrlmsise00 failed. Please install nrlmsise00 via pip."
            rethrow(e)
        end
    end
end