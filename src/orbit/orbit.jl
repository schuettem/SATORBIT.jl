struct Satellite
    c_d::Float64
    area::Float64
    mass::Float64
end

struct COES # Classical Orbital Elements
    a::Float64 # semi-major axis
    e::Float64 # eccentricity
    i::Float64 # inclination
    Ω::Float64 # right ascension of the ascending node
    ω::Float64 # argument of periapsis
    f::Float64 # true anomaly
end

struct ECI
    r::Vector{Float64} # position in the inertial frame
    v::Vector{Float64} # velocity in the inertial frame
end

struct GEO
    latitude::Float64
    longitude::Float64
end

struct ECEF
    r::Vector{Float64}
end

struct Atmosphere
    n_o::Float64
    T::Float64
    v_ref::Float64
end

mutable struct Orbit
    satellite::Satellite
    central_body::Planet
    eci::Vector{ECI}
    time_utc::Vector{DateTime}
    time_et::Vector{Float64}
end

function Orbit(satellite::Satellite, central_body::Planet, eci::ECI, time_utc::DateTime, time_et::Float64)
    return Orbit(satellite, central_body, [eci], [time_utc], [time_et])
end

function Orbit(satellite::Satellite, central_body::Planet, coes::COES, time_utc::DateTime)
    r, v = coes2eci(coes, central_body.μ)
    eci = ECI(r, v)
    time_et = utc2et(time_utc)
    return Orbit(satellite, central_body, [eci], [time_utc], [time_et])
end

"""
    Equation of motion for the satellite. This function will be used by the differential equation solver.
"""
function equations_of_motion!(du, u, p, t)
    central_body, satellite, disturbances = p
    r = u[1:3]
    v = u[4:6]

    # utc time
    utc_time = et2utc(t, "ISOC", 0)
    utc_time = DateTime(utc_time, "yyyy-mm-ddTHH:MM:SS")

    # calculate the acceleration
    a = acceleration(central_body, satellite, r, v, disturbances, utc_time)

    # update the derivatives
    du[1:3] = v
    du[4:6] = a
end

function set_parameters!(orbit::Orbit, eci::ECI, time_et::Float64, time_utc::DateTime)
    # et:
    push!(orbit.time_et, time_et)

    # utc:
    push!(orbit.time_utc, time_utc)

    # ECI:
    push!(orbit.eci, eci)
end