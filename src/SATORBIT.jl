module SATORBIT

# Packages:
using PyCall
using Dates
using LinearAlgebra
# using CairoMakie
using GLMakie
using CSV
using DataFrames
using Statistics
using SPICE
using GeometryBasics: Point3f0

# SPICE Kernel:
# SPICE Kernel paths
const leapseconds_kernel = joinpath(@__DIR__, "spice_kernels/latest_leapseconds.tls")
const earth_kernel = joinpath(@__DIR__, "spice_kernels/earth_620120_240827.bpc") # Earth orientation history kernel

# import Python Packages
const nrlmsise00 = PyNULL()

function __init__()
    # Load SPICE Kernels
    if isfile(leapseconds_kernel) && isfile(earth_kernel)
        furnsh(leapseconds_kernel)
        furnsh(earth_kernel)
    else
        error("One or more SPICE kernel files are missing.")
    end

    # Import Python package
    copy!(nrlmsise00, pyimport("nrlmsise00"))
end

# Include files:
include("planetary_data/earth.jl")
include("satellite.jl")
include("orbit/pertubations.jl")
include("orbit/orbit.jl")
include("transformation/coordinate_transformation.jl")

include("atmosphere/atmosphere.jl")
include("atmosphere/spaceweather.jl")
include("orbit/acceleration.jl")

include("plot/plot_3d.jl")
include("plot/plot_ground_track.jl")
include("plot/plot_atmosphere.jl")
include("plot/plot_coes.jl")
include("plot/plot_animation.jl")

# Constants:
GRAVITY_CONSTANT = 6.67430e-11 # m^3 kg^-1 s^-2

function simulate_orbit(satellite::Satellite, central_body::Earth, init_orbit::COES, start_date::DateTime, disturbances::Pertubations, nbr_orbits::Int64, nbr_steps::Int64)
    orbit = OrbitPropagation([init_orbit], [], [], [], [], [start_date], [utc2et(start_date)])
    spaceweather_df = spaceweather()

    orbit_propagator!(satellite, central_body, orbit, disturbances, spaceweather_df, nbr_orbits, nbr_steps)
    return orbit
end

end
