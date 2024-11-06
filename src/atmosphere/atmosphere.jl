"""
    Calculate the atmosphere at a given altitude, latitude, longitude, and time

    altitude: altitude in meters
    latitude: latitude in degrees
    longitude: longitude in degrees
    f107a: 81-day average of F10.7 flux
    f107: daily F10.7 flux
    ap: magnetic index
"""
function calc_atmosphere(date_time::DateTime, altitude, latitude, longitude, f107, f107a, ap)
    return nrlmsise00.msise_flat(date_time, altitude / 1e3, latitude, longitude, f107, f107a, ap)
end

"""
    Calculate the horizontal wind at a given altitude, latitude, longitude, and time
"""
function wind(date::DateTime, alt::Float64, glat::Float64, glon::Float64, stl::Float64, f107a::Float64, f107::Float64, ap::Vector{Float64})
    # convert date to iyd and sec
    iyd, sec = HWM14.datetime2iydsec(date)

    # calculate wind
    w = HWM14.hwm14(iyd, sec, alt, glat, glon, stl, f107a, f107, ap)
    # transform Vector{Float32} to Vector{Float64}
    w = convert(Vector{Float64}, w)

    # convert from geodetic to ECEF
    w = wind2eci(w, glat, glon, date)
    return w
end

"""
    Calculate the velocity of the atmosphere due to the rotation of the Earth
"""
function atmosphere_rotation(r::Vector{Float64}, central_body::Earth)
    return cross(central_body.atm_rot_vec, r)
end

function rel_velocity_to_atm(r::Vector{Float64}, v::Vector{Float64}, central_body::Earth, date::DateTime, lat::Float64, lon::Float64, stl::Float64, f107a::Float64, f107::Float64, ap::Vector{Float64})
    # ALtitude of the satellite in km
    alt = norm(r) - central_body.radius

    # Relative velocity with respect to the atmosphere
    v_atm_rot = cross(central_body.atm_rot_vec, r) # r in ECI
    v_wind = wind(date, alt, lat, lon, stl, f107a, f107, ap) # v_wind in ECI
    v_rel = v - v_atm_rot - v_wind # v , r in ECI
    v_rel_norm = norm(v_rel)
    return v_rel_norm
end

include("get_densities_temp.jl")