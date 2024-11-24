module SATORBIT

# Packages:
using Dates
using LinearAlgebra
using CairoMakie
using GLMakie
using CSV
using DataFrames
using Statistics
using SPICE
using OrdinaryDiffEq
using Pkg
using PyCall
using HWM14
using Base.Filesystem: stat
using HTTP
using SpecialFunctions
using GeoMakie
using SatelliteToolboxAtmosphericModels

# Include files:
include("planetary_data/earth.jl")
include("orbit/pertubations.jl")
include("orbit/orbit.jl")
include("transformation/coordinate_transformation.jl")

include("atmosphere/atmosphere.jl")
include("spaceweather/spaceweather.jl")
include("spaceweather/spaceweather_historical.jl")
include("spaceweather/spaceweather_daily_forecast.jl")
include("spaceweather/spaceweather_monthly_forecast.jl")
include("orbit/acceleration.jl")

include("plot/plot_3d.jl")
include("plot/plot_ground_track.jl")
include("plot/plot_atmosphere.jl")
include("plot/plot_coes.jl")

include("check_and_install.jl")

const leapseconds_kernel = joinpath(@__DIR__, "spice_kernels/latest_leapseconds.tls")
const earth_kernel = joinpath(@__DIR__, "spice_kernels/earth_1962_240827_2124_combined.bpc") # Earth orientation history and predicted kernel

const spaceweather_historical_data = Ref{DataFrame}(DataFrame())
const spaceweather_daily_forecast_data = Ref{DataFrame}(DataFrame())
const spaceweather_monthly_forecast_data = Ref{DataFrame}(DataFrame())

function __init__()
    # SPICE
    # The SPICE kernels used in this script are provided by the NASA Navigation and Ancillary Information Facility (NAIF).
    # Data Source: NAIF Generic Kernels (https://naif.jpl.nasa.gov/naif/data_generic.html).
    check_and_install_spice_earth_kernel()
    check_and_install_spice_leapseconds_kernel()

    # Space weather data
    spaceweather_historical_data[] = check_and_install_spaceweather_historical() # Historical space weather data from GFZ Potsdam
    spaceweather_daily_forecast_data[] = check_and_install_spaceweather_daily_forecast() # Daily space weather forecast data from NOAA
    spaceweather_monthly_forecast_data[] = check_and_install_spaceweather_monthly_forecast() # Monthly space weather forecast data from NASA Marshall Space Flight Center
end

# Constants:
GRAVITY_CONSTANT = 6.67430e-11 # m^3 kg^-1 s^-2

"""
    simulate orbit function
"""
function simulate_orbit!(orbit::Orbit, disturbances::Pertubations, nbr_orbits::Number, nbr_steps::Int64)
    # initial position and velocity in the ECI frame
    r_0 = orbit.eci[end].r # end because the last position is the initial position for the next orbit
    v_0 = orbit.eci[end].v # end because the last velocity is the initial velocity for the next orbit
    u_0 = vcat(r_0, v_0) # initial state vector

    # Time span
    t_0 = orbit.time_et[end] # time in ephemeris time
    a, _, _, _, _, _ = eci2coes(r_0, v_0, orbit.central_body.μ)
    P = 2 * π * a ^ (3/2) / sqrt(orbit.central_body.μ) # period of the orbit in seconds
    t_end = t_0 + nbr_orbits * P
    tspan = (t_0, t_end)

    # Parameters
    p = (orbit.central_body, orbit.satellite, disturbances)

    # Define the problem
    prob = ODEProblem(equations_of_motion!, u_0, tspan, p)

    # Solve the problem
    sol = solve(prob, Tsit5(), abstol=1e-9, reltol=1e-9, saveat=range(t_0, t_end, length=nbr_steps))

    for i in 1:length(sol.t)
        r = sol[i][1:3] # position in the eci frame
        v = sol[i][4:6] # velocity in the eci frame
        time_et = sol.t[i] # time in ephemeris time
        time_utc = et2utc(time_et, "ISOC", 0) # time in utc
        time_utc = DateTime(time_utc, "yyyy-mm-ddTHH:MM:SS") # convert to DateTime
        set_parameters!(orbit, ECI(r, v), time_et, time_utc) # set parameters for the first orbit
    end
end
end