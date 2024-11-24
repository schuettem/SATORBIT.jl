function acceleration(central_body::Earth, satellite::Satellite, r_eci::Vector{Float64}, v_eci::Vector{Float64}, disturbances::Pertubations, time_utc::DateTime)
    # gravitational acceleration
    a_grav = newton(central_body, r_eci)

    # J2 pertubation
    if disturbances.J2
        a_J2 = J2(central_body, r_eci)
    else
        a_J2 = [0.0, 0.0, 0.0]
    end

    # atmospheric drag
    if disturbances.aero
        # Latitude and longitude
        r_ecef = eci2ecef(r_eci, time_utc)
        latitude, longitude = ecef2geo(r_ecef)
        # Atmospheric data:
        f107, f107a, ap = get_spaceweather(time_utc)
        atm = AtmosphericModels.nrlmsise00(time_utc, norm(r_eci) - central_body.radius, deg2rad(latitude), deg2rad(longitude), f107a, f107, ap)
        ρ = atm.total_density
        v_rel = rel_velocity_to_atm(r_eci, v_eci, central_body, time_utc, latitude, longitude, 0.0, f107a, f107, [0.0, ap])
        a_drag = drag(satellite, v_rel, ρ)
    else
        a_drag = [0.0, 0.0, 0.0]
    end
    return a_grav + a_J2 + a_drag
end

"""
    Newton's gravitational law
"""
function newton(central_body::Planet, r::Vector{Float64})
    # Newton's gravitational law
    return - central_body.μ / norm(r)^3 * r
end

"""
    J2 pertubation
"""
function J2(central_body::Earth, r::Vector{Float64})
    # J2 pertubation
    J2 = central_body.J2
    R = central_body.radius
    μ = central_body.μ

    z2 = r[3]^3
    r2 = norm(r)^2
    tx = r[1] / norm(r) * (5 * z2 / r2 - 1)
    ty = r[2] / norm(r) * (5 * z2 / r2 - 1)
    tz = r[3] / norm(r) * (5 * z2 / r2 - 3)

    a_J2 = 3/2 * J2 * μ * R^2 / r2^2 * [tx, ty, tz]

    return a_J2
end

"""
    atmospheric drag
"""
function drag(satellite::Satellite, v_rel::Vector{Float64}, ρ::Float64)
    # Satellite
    A = satellite.area
    m = satellite.mass
    c_d = satellite.c_d

    # Drag acceleration
    a_drag = - 1/2 * ρ * A * c_d / m * norm(v_rel) * v_rel
    return a_drag
end