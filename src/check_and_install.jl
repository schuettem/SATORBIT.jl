# Check and install nrlmsise00 Python package
function check_and_install_nrlmsise00()
    try
        @info "loading nrlmsise00"
        return pyimport("nrlmsise00")
    catch e
        if isa(e, PyCall.PyError) && occursin("PyImport_ImportModule", e.msg)
            @info "start installing nrlmsise00 via pip..."
            run(`$(PyCall.python) -m pip install nrlmsise00`)
            @info "installing nrlmsise00 finished."
            return pyimport("nrlmsise00")
        else
            @info "installing of nrlmsise00 failed. Please install nrlmsise00 via pip."
            rethrow(e)
        end
    end
end