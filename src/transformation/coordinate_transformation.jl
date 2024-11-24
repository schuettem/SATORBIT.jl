"""
    transform coes (classical orbital elements) to rv (position and velocity) in the inertial frame
"""
function coes2eci(orbit::COES, μ::Float64)
    a = orbit.a # semi-major axis
    e = orbit.e # eccentricity
    i = deg2rad(orbit.i) # inclination
    Ω = deg2rad(orbit.Ω) # right ascension of the ascending node
    ω = deg2rad(orbit.ω) # argument of periapsis
    f = deg2rad(orbit.f) # true anomaly

    p = a * (1 - e^2) # semi-latus rectum
    r = p / (1 + e * cos(f)) # distance from the central body

    # Position in the perifocal frame
    r_pqw = [r * cos(f), r * sin(f), 0.0]

    # Velocity in the perifocal frame
    v_pqw = sqrt(μ / p) * [-sin(f), e + cos(f), 0.0]

    R_3_Ω = [cos(Ω) -sin(Ω) 0.0; sin(Ω) cos(Ω) 0.0; 0.0 0.0 1.0]
    R_1_i = [1.0 0.0 0.0; 0.0 cos(i) -sin(i); 0.0 sin(i) cos(i)]
    R_3_ω = [cos(ω) -sin(ω) 0.0; sin(ω) cos(ω) 0.0; 0.0 0.0 1.0]

    R_pqw_eci = R_3_Ω * R_1_i * R_3_ω

    r_eci = R_pqw_eci * r_pqw
    v_eci = R_pqw_eci * v_pqw

    return r_eci, v_eci
end

function eci2coes(r::Vector{Float64}, v::Vector{Float64}, μ::Float64)
    r_mag = norm(r)
    v_mag = norm(v)

    # specific angular momentum vector
    h = cross(r, v)
    h_mag = norm(h)

    # inclination
    i = acos(h[3] / h_mag)

    # Node vector
    n = [-h[2], h[1], 0.0]
    n_mag = norm(n)

    # right ascension of the ascending node
    if n_mag ≈ 0
        Ω = 0 # Ω is undefined if n_mag = 0 (i.e. the orbit is equatorial)
    else
        Ω = acos(n[1] / n_mag)
        if n[2] < 0
            Ω = 2 * π - Ω
        end
    end

    # Eccentricity vector
    e_vec = (1 / μ) * ((v_mag^2 - μ / r_mag) * r - dot(r, v) * v)
    e = norm(e_vec)

    # Argument of periapsis
    if e < 1e-5
        ω = 0 # ω is undefined if e = 0
    else
        if n_mag ≈ 0 # orbit is equatorial
            ω = atan(e_vec[2], e_vec[1])
            if ω < 0
                ω += 2 * π
            end
        else
            ω = acos(dot(n, e_vec) / (n_mag * e))
            if e_vec[3] < 0
                ω = 2 * π - ω
            end
        end
    end

    # true anomaly
    if e < 1e-5
        if n_mag ≈ 0 # n ≠ 0
            # Special case for circular equatorial orbits
            u = atan(r[2], r[1])
            if u < 0
                u += 2 * π
            end
            f = u
        else
            f = acos(dot(n, r) / (n_mag * r_mag))
            if r[3] < 0
                f = 2 * π - f
            end
        end
    else # e ≠ 0
        f = acos(dot(e_vec, r) / (e * r_mag))
        if dot(r, v) < 0
            f = 2 * π - f
        end
    end

    # Semi-major axis
    a = 1 / (2 / r_mag - v_mag^2 / μ)

    return a, e, rad2deg(i), rad2deg(Ω), rad2deg(ω), rad2deg(f)
end

"""
    transform ecef (earth-centered, earth-fixed) to geodetic coordinates
"""
function ecef2geo(r::Vector{Float64})
    r_mag, lon, lat = reclat(r)
    return rad2deg(lat), rad2deg(lon)
end

"""
    transform geodetic coordinates to ecef (earth-centered, earth-fixed)
"""
function geo2ecef(lat::Float64, lon::Float64, r_mag::Float64)
    r_x = r_mag * cos(lat) * cos(lon)
    r_y = r_mag * cos(lat) * sin(lon)
    r_z = r_mag * sin(lat)
    return [r_x, r_y, r_z]
end

"""
    transform eci (earth-centered inertial) to ecef (earth-centered, earth-fixed)
"""
function eci2ecef(r::Vector{Float64}, time_utc::DateTime)
    R_eci_ecef = pxform("J2000", "ITRF93", utc2et(time_utc))
    r_ecef = R_eci_ecef * r
    return r_ecef
end

"""
    transform ecef (earth-centered, earth-fixed) to eci (earth-centered inertial)
"""
function ecef2eci(r::Vector{Float64}, time_utc::DateTime)
    R_ecef_eci = pxform("ITRF93", "J2000", utc2et(time_utc))
    r_eci = R_ecef_eci * r
    return r_eci
end

"""
    transform meridonal wind and zonal wind to the eci frame
    w[1]: meridional wind
    w[2]: zonal wind
"""
function wind2eci(w::Vector{Float64}, lat::Float64, lon::Float64, time_utc::DateTime)
    # Preallocate the wind velocity vector in ECEF coordinates
    w_ecef = Vector{Float64}(undef, 3)
    w_eci = Vector{Float64}(undef, 3)

    # Wind velocity vector in ECEF coordinates (assuming flat Earth approximation)
    w_ecef[1] = -w[2] * sind(lon) - w[1] * sind(lat) * cosd(lon)
    w_ecef[2] =  w[2] * cosd(lon) - w[1] * sind(lat) * sind(lon)
    w_ecef[3] =  w[1] * cosd(lat)

    # Rotation matrix from ECEF to ECI
    R_ecef_eci = pxform("ITRF93", "J2000", utc2et(time_utc))

    # Transform the wind velocity vector to ECI
    mul!(w_eci, R_ecef_eci, w_ecef)
    return w_eci
end

"""
    transform eci (earth-centered inertial) to tnw (tangential, normal, and radial)

    t - tangential: along the of the orbit
    n - normal: perpendicular to the orbit plane, along the angular momentum vector
    w - cross track: completes the right-handed coordinate system, pointing towards the center of the orbit.
"""
function eci2tnw(r_eci::Vector{Float64}, v_eci::Vector{Float64})
    # Calculate the tangential (T) vector
    T = normalize(v_eci) # unit velocity vector

    # Calculate the normal (N) vector (angular momentum vector)
    h = cross(r_eci, v_eci)
    N = normalize(h) # unit angular momentum vector

    # Calculate the cross-track (W) vector
    W = cross(T, N)

    # Construct the rotation matrix from ECI to TNW
    R_eci_tnw = hcat(T, W, N)

    # Transform the velocity from ECI to TNW
    v_tnw = R_eci_tnw' * v_eci

    return v_tnw
end
