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

mutable struct OrbitPropagation
    coes::Vector{COES}
    eci::Vector{ECI}
    geo::Vector{GEO}
    ecef::Vector{ECEF}
    atmosphere_data::Vector{Atmosphere}
    time_utc::Vector{DateTime}
    time_et::Vector{Float64}
end

"""
    Equation of motion for the satellite. This function will be used by the differential equation solver.
"""
function equations_of_motion!(du, u, p, t)
    central_body, satellite, disturbances, spaceweather_df = p
    r = u[1:3]
    v = u[4:6]

    # utc time
    utc_time = et2utc(t, "ISOC", 0)
    utc_time = DateTime(utc_time, "yyyy-mm-ddTHH:MM:SS")

    # calculate the acceleration
    a = acceleration(central_body, satellite, r, v, disturbances, spaceweather_df, utc_time)

    # update the derivatives
    du[1:3] = v
    du[4:6] = a
end

function set_parameters!(orbit::OrbitPropagation, eci::ECI, central_body::Earth, time_et, time_utc::DateTime, spaceweather_df::DataFrame)
    # et:
    push!(orbit.time_et, time_et)

    # utc:
    push!(orbit.time_utc, time_utc)

    # ECI:
    push!(orbit.eci, eci)

    # COES:
    a, e, i, Ω, ω, f = eci2coes(eci.r, eci.v, central_body.μ)
    push!(orbit.coes, COES(a, e, i, Ω, ω, f))

    # ECEF:
    r_ecef = eci2ecef(eci.r, time_utc)
    push!(orbit.ecef, ECEF(r_ecef))

    # Geodetic:
    latitude, longitude = ecef2geo(r_ecef)
    push!(orbit.geo, GEO(latitude, longitude))

    # Atmospheric data:
    f107a = f107adj_81avg(time_utc, spaceweather_df)
    f107 = f107adj_day(time_utc, spaceweather_df)
    ap = ap_at(time_utc, spaceweather_df)
    atm = calc_atmosphere(time_utc, norm(eci.r) - central_body.radius, latitude, longitude, f107a, f107, ap)
    n_o = get_o_density(atm)
    T = get_temperature(atm)
    v_ref = rel_velocity_to_atm(eci.r, eci.v, central_body)
    push!(orbit.atmosphere_data, Atmosphere(n_o, T, v_ref))
end