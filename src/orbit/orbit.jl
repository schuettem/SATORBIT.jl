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

function propagate_orbit!(satellite::Satellite, central_body::Earth, orbit::OrbitPropagation, disturbances::Pertubations, spaceweather_df::DataFrame, nbr_orbits::Int64, nbr_steps::Int64)
    # times:
    t_0 = utc2et(orbit.time_utc[1]) # transform start data from utc in emphemeris time (ET) in seconds since J2000
    P = 2 * π * orbit.coes[1].a ^ (3/2) / sqrt(central_body.μ) # period of the orbit in seconds
    t_end = t_0 + nbr_orbits * P
    Δt = (t_end - t_0) / nbr_steps

    set_parameters!(orbit, orbit.coes[1], central_body, orbit.time_utc[1], spaceweather_df) # set parameters for the first orbit

    # propagate the orbit:
    for i in 2:nbr_steps
        t_et = t_0 + (i - 1) * Δt

        push!(orbit.time_et, t_et) # store ET
        utc_time = et2utc(t_et, "ISOC", 0) # transform ET to UTC
        push!(orbit.time_utc, DateTime(utc_time, "yyyy-mm-ddTHH:MM:SS")) # transform ET to UTC

        r_eci, v_eci = runge_kutta_4(central_body, satellite, orbit.eci[end].r, orbit.eci[end].v, Δt, disturbances) # in ECI

        set_parameters!(orbit, ECI(r_eci, v_eci), central_body, orbit.time_utc[end], spaceweather_df)
    end
end

# Implement the 4th-order Runge-Kutta method
function runge_kutta_4(central_body, satellite, r, v, dt, disturbances)
    k1_v = acceleration(central_body, satellite, r, v, disturbances) * dt
    k1_r = v * dt

    k2_v = acceleration(central_body, satellite, r + 0.5 * k1_r, v + 0.5 * k1_v, disturbances) * dt
    k2_r = (v + 0.5 * k1_v) * dt

    k3_v = acceleration(central_body, satellite, r + 0.5 * k2_r, v + 0.5 * k2_v, disturbances) * dt
    k3_r = (v + 0.5 * k2_v) * dt

    k4_v = acceleration(central_body, satellite, r + k3_r, v + k3_v, disturbances) * dt
    k4_r = (v + k3_v) * dt

    r_new = r + (k1_r + 2*k2_r + 2*k3_r + k4_r) / 6
    v_new = v + (k1_v + 2*k2_v + 2*k3_v + k4_v) / 6

    return r_new, v_new
end

function set_parameters!(orbit::OrbitPropagation, coes::COES, central_body::Earth, time_utc::DateTime, spaceweather_df::DataFrame)
    # ECI:
    r_eci, v_eci = coes2eci(coes, central_body.μ)
    push!(orbit.eci, ECI(r_eci, v_eci))
    # ECEF:
    r_ecef = eci2ecef(r_eci, time_utc)
    push!(orbit.ecef, ECEF(r_ecef))
    # Geodetic:
    latitude, longitude = ecef2geo(r_ecef)
    push!(orbit.geo, GEO(latitude, longitude))
    # Atmospheric data:
    f107a = f107adj_81avg(time_utc, spaceweather_df)
    f107 = f107adj_day(time_utc, spaceweather_df)
    ap = ap_at(time_utc, spaceweather_df)
    atm = calc_atmosphere(time_utc, norm(r_eci) - central_body.radius, latitude, longitude, f107a, f107, ap)
    n_o = get_o_density(atm)
    T = get_temperature(atm)
    v_ref = rel_velocity_to_atm(r_eci, v_eci, central_body)
    push!(orbit.atmosphere_data, Atmosphere(n_o, T, v_ref))
end

function set_parameters!(orbit::OrbitPropagation, eci::ECI, central_body::Earth, time_utc::DateTime, spaceweather_df::DataFrame)
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