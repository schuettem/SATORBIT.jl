module SATORBIT

# Packages:
using PyCall
using Dates
using LinearAlgebra
using CairoMakie
using GLMakie
using CSV
using DataFrames
using Statistics
using SPICE
using DifferentialEquations
using HWM14

# The SPICE kernels used in this script are provided by the NASA Navigation and Ancillary Information Facility (NAIF).
# Data Source: NAIF Generic Kernels (https://naif.jpl.nasa.gov/naif/data_generic.html).
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

# Constants:
GRAVITY_CONSTANT = 6.67430e-11 # m^3 kg^-1 s^-2

function simulate_orbit(satellite::Satellite, central_body::Earth, init_orbit::COES, start_date::DateTime, disturbances::Pertubations, nbr_orbits::Number, nbr_steps::Int64)
    # Initial conditions
    r_0, v_0 = coes2eci(init_orbit, central_body.μ) # initial position and velocity in the ECI frame
    u_0 = vcat(r_0, v_0) # initial state vector

    # Time span
    t_0 = utc2et(start_date) # transform start data from utc in emphemeris time (ET) in seconds since J2000
    P = 2 * π * init_orbit.a ^ (3/2) / sqrt(central_body.μ) # period of the orbit in seconds
    t_end = t_0 + nbr_orbits * P
    tspan = (t_0, t_end)

    # Parameters
    spaceweather_df = spaceweather()
    p = (central_body, satellite, disturbances, spaceweather_df)

    # Define the problem
    prob = ODEProblem(equations_of_motion!, u_0, tspan, p)

    # Solve the problem
    sol = solve(prob, Tsit5(), abstol=1e-9, reltol=1e-9, saveat=range(t_0, t_end, length=nbr_steps))#, Tsit5(), abstol=0.00002)

    orbit = OrbitPropagation([], [], [], [], [], [], [])
    for i in 1:length(sol.t)
        r = sol[i][1:3] # position in the eci frame
        v = sol[i][4:6] # velocity in the eci frame
        time_et = sol.t[i] # time in ephemeris time
        time_utc = et2utc(time_et, "ISOC", 0) # time in utc
        time_utc = DateTime(time_utc, "yyyy-mm-ddTHH:MM:SS") # convert to DateTime

        set_parameters!(orbit, ECI(r, v), central_body, time_et, time_utc, spaceweather_df) # set parameters for the first orbit
    end
    return orbit
end
end