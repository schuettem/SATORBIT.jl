struct Atmosphere
    he_density::Float64
    o_density::Float64
    n2_density::Float64
    o2_density::Float64
    ar_density::Float64
    total_mass_density::Float64
    h_density::Float64
    n_density::Float64
    anomalous_o_density::Float64
    temperature::Float64
    exo_temperature::Float64
    velocity::Vector{Float64}

    function Atmosphere(atm, velocity)
        he_density = atm.He_number_density
        o_density = atm.O_number_density
        n2_density = atm.N2_number_density
        o2_density = atm.O2_number_density
        ar_density = atm.Ar_number_density
        total_mass_density = atm.total_density
        h_density = atm.H_number_density
        n_density = atm.N_number_density
        anomalous_o_density = atm.aO_number_density
        temperature = atm.temperature
        exo_temperature = atm.exospheric_temperature
        new(he_density, o_density, n2_density, o2_density, ar_density, total_mass_density, h_density, n_density, anomalous_o_density, temperature, exo_temperature, velocity)
    end
end

"""
    Get the atmospheric data from the NRLMSISE-00 model and HWM14 model

    r: position vector of the satellite in the ECI frame
    date_time: date and time in UTC
    central_body: central body
"""
function get_atmosphere_data(r::Vector{Float64}, date_time::DateTime, central_body::Earth)
    r_ecef = eci2ecef(r, date_time) # r in ECEF
    latitude, longitude = ecef2geo(r_ecef) # latitude and longitude in degrees
    altitude = norm(r) - central_body.radius # altitude in meters

    f107, f107a, ap = get_spaceweather(date_time)

    atm = AtmosphericModels.nrlmsise00(date_time, altitude, deg2rad(latitude), deg2rad(longitude), f107a, f107, ap)

    v_atm_rot = cross(central_body.atm_rot_vec, r)
    v_wind = wind(date_time, altitude / 1e3, latitude, longitude, 0.0, f107, f107a, [0.0, ap]) # v_wind in ECI
    velocity = v_atm_rot + v_wind # velocity of the atmosphere in the ECI frame
    return Atmosphere(atm, velocity)
end

"""
    Get the NRLMSISE00 data at a given altitude, latitude, longitude, and time

    altitude: altitude in meters
    latitude: latitude in degrees
    longitude: longitude in degrees
    f107a: 81-day average of F10.7 flux
    f107: daily F10.7 flux
    ap: magnetic index

    return: NRLMSISE00 data as an array
"""
function get_nrlmsise00_data(date_time::DateTime, altitude, latitude, longitude, f107, f107a, ap)
    return nrlmsise00.msise_flat(date_time, altitude / 1e3, latitude, longitude, f107, f107a, ap)
end

"""
    Calculate the horizontal wind at a given altitude, latitude, longitude, and time

    date: date and time in UTC
    alt: altitude in km
    glat: geodetic latitude in degrees
    glon: geodetic longitude in degrees
"""
function wind(date::DateTime, alt::Float64, glat::Float64, glon::Float64, stl::Float64, f107::Float64, f107a::Float64, ap::Vector{Float64})
    # convert date to iyd and sec
    iyd, sec = HWM14.datetime2iydsec(date)

    # calculate wind
    w = HWM14.hwm14(iyd, sec, alt, glat, glon, stl, f107a, f107, ap)
    # transform Vector{Float32} to Vector{Float64}
    w = convert(Vector{Float64}, w)

    # convert from geo to ECI
    w = wind2eci(w, glat, glon, date)
    return w
end

"""
    Calculate the velocity of the atmosphere due to the rotation of the Earth
"""
function atmosphere_rotation(r::Vector{Float64}, central_body::Earth)
    return cross(central_body.atm_rot_vec, r)
end

"""
    Calculate the relative velocity of the satellite with respect to the atmosphere

    r: position vector of the satellite in the ECI frame
    v: velocity vector of the satellite in the ECI frame
    central_body: central body
    date: date and time in UTC
"""
function rel_velocity_to_atm(r::Vector{Float64}, v::Vector{Float64}, central_body::Earth, date_time::DateTime, lat::Float64, lon::Float64, stl::Float64, f107a::Float64, f107::Float64, ap::Vector{Float64})
    # ALtitude of the satellite in km
    alt = norm(r) - central_body.radius

    # Relative velocity with respect to the atmosphere
    v_atm_rot = cross(central_body.atm_rot_vec, r) # r in ECI
    v_wind = wind(date_time, alt, lat, lon, stl, f107a, f107, ap) # v_wind in ECI
    v_rel = v - v_atm_rot - v_wind # v , r in ECI
    return v_rel
end

"""
    Calculate the atmospheric conditions at each time step in the orbit
"""
function atmosphere_orbit_data(orbit::Orbit)
    nrlmsise00_data = Atmosphere[] # List of atmosphere data at each time step in the orbit

    # Calculate the atmospheric conditions:
    for (i, utc) in enumerate(orbit.time_utc)

        eci = orbit.eci[i]
        atm = get_atmosphere_data(eci.r, utc, orbit.central_body)

        push!(nrlmsise00_data, atm)
    end
    return nrlmsise00_data
end

function calc_nbr_flux_density(density::Float64, velocity_n::Float64, temperature::Float64)
    c_m = most_probable_speed(temperature)
    s_n = velocity_n / c_m
    return density * c_m * 1/(2 *sqrt(π)) * (exp(-s_n^2) + √(π) * s_n * (1 + erf(s_n))) # Bird 1994
end

function most_probable_speed(temperature::Float64)
    k_B = 1.38064852e-23 # Boltzmann constant
    m_AOX = 2.657E-26 # mass atomic oxygen
    return sqrt(2 * k_B * temperature / m_AOX)
end

include("get_densities_temp.jl")