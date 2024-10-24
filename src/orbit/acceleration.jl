function acceleration(central_body::Earth, satellite::Satellite, r_eci::Vector{Float64}, v_eci::Vector{Float64}, disturbances::Pertubations)
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
        error("Atmospheric drag not implemented yet")
        ρ = get_total_mass_density(atmosphere_data)
        a_drag = drag(satellite, v_rel_norm, ρ)
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
function drag(satellite::Satellite, v_rel_norm::Float64, ρ::Float64)
    # Satellite
    A = satellite.area
    m = satellite.mass
    c_d = satellite.c_d

    # Drag acceleration
    a_drag = - 1/2 * ρ * A * c_d / m * v_rel_norm * v_rel
    return a_drag
end

function rel_velocity_to_atm(r::Vector{Float64}, v::Vector{Float64}, central_body::Earth)
    # Relative velocity with respect to the atmosphere
    v_rel = v - cross(central_body.atm_rot_vec, r) # v , r in ECI
    v_rel_norm = norm(v_rel)
    return v_rel_norm
end