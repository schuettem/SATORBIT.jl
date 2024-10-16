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
    v = sqrt(μ / p) # velocity magnitude

    r_pqw = [r * cos(f), r * sin(f), 0.0] # position in the perifocal frame
    v_pqw = [-v * sin(f), v * (e + cos(f)), 0.0] # velocity in the perifocal frame

    R_3_Ω = [cos(Ω) -sin(Ω) 0.0; sin(Ω) cos(Ω) 0.0; 0.0 0.0 1.0]
    R_1_i = [1.0 0.0 0.0; 0.0 cos(i) -sin(i); 0.0 sin(i) cos(i)]
    R_3_ω = [cos(ω) -sin(ω) 0.0; sin(ω) cos(ω) 0.0; 0.0 0.0 1.0]

    R_pqw_eci = R_3_Ω * R_1_i * R_3_ω

    r_eci = R_pqw_eci * r_pqw
    v_eci = R_pqw_eci * v_pqw

    return r_eci, v_eci
end

function eci2coes(r::Vector{Float64}, v::Vector{Float64}, μ::Float64)
    # Angular momentum vector
    h = cross(r, v)
    h_norm = norm(h)

    # Eccentricity vector
    e_vec = ((norm(v)^2 - μ / norm(r)) * r - dot(r, v) * v) / μ
    e = norm(e_vec)

    # Inclination
    i = acos(h[3] / h_norm)

    # Node vector
    K = [0.0, 0.0, 1.0]
    n = cross(K, h)
    n_norm = norm(n)

    # Right ascension of the ascending node
    Ω = acos(n[1] / n_norm)
    if n[2] < 0 # If n[2] < 0, then 180° < Ω < 360°
        Ω = 2 * π - Ω
    end

    # Argument of periapsis
    ω = acos(dot(n, e_vec) / (n_norm * e))
    if e_vec[3] < 0 # If e_vec[3] < 0, then 180° < ω < 360°
        ω = 2 * π - ω
    end

    # True anomaly
    f = acos(dot(e_vec, r) / (e * norm(r)))
    if dot(r, v) < 0 # If r · v < 0, then 180° < f < 360°
        f = 2 * π - f
    end

    # Semi-major axis
    a = norm(r) * (1 + e * cos(f)) / (1 - e^2)


    return (a, e, rad2deg(i), rad2deg(Ω), rad2deg(ω), rad2deg(f))
end

"""
    transform ecef (earth-centered, earth-fixed) to geodetic coordinates
"""
function ecef2geo(r::Vector{Float64})
    r_mag, lon, lat = reclat(r)

    # x = r[1]
    # y = r[2]
    # z = r[3]

    # # Constants for WGS-84
    # a = 6378137.0  # Semi-major axis
    # f = 1 / 298.257223563  # Flattening
    # b = a * (1 - f)  # Semi-minor axis
    # e_sq = f * (2 - f)  # Square of eccentricity

    # r = sqrt(x^2 + y^2)
    # Esq = a^2 - b^2
    # F = 54 * b^2 * z^2
    # G = r^2 + (1 - e_sq) * z^2 - e_sq * Esq
    # c = (e_sq^2 * F * r^2) / (G^3)
    # s = (1 + c + sqrt(c^2 + 2 * c))^(1/3)
    # P = F / (3 * (s + 1/s + 1)^2 * G^2)
    # Q = sqrt(1 + 2 * e_sq^2 * P)
    # r_0 = -(P * e_sq * r) / (1 + Q) + sqrt(0.5 * a^2 * (1 + 1/Q) - P * (1 - e_sq) * z^2 / (Q * (1 + Q)) - 0.5 * P * r^2)
    # U = sqrt((r - e_sq * r_0)^2 + z^2)
    # V = sqrt((r - e_sq * r_0)^2 + (1 - e_sq) * z^2)
    # Z_0 = b^2 * z / (a * V)
    # h = U * (1 - b^2 / (a * V))
    # lat = atan((z + e_sq * Z_0) / r)
    # lon = atan(y, x)

    return rad2deg(lat), rad2deg(lon)
end

"""
    transform eci (earth-centered inertial) to ecef (earth-centered, earth-fixed)
"""
function eci2ecef(r::Vector{Float64}, time_utc::DateTime)
    R_eci_ecef = pxform("J2000", "ITRF93", utc2et(time_utc))
    r_ecef = R_eci_ecef * r

    # # Define the Earth's rotation rate
    # ω_e = 7.2921150e-5 # rad/s

    # # Calculate the number of seconds since J2000 epoch
    # j2000_epoch = DateTime(2000, 1, 1, 12, 0, 0)
    # Δt = time_utc - j2000_epoch
    # elapsed_seconds = Δt.value / 1e3 # Convert milliseconds to seconds

    # # Calculate the angle of rotation
    # θ = mod(ω_e * elapsed_seconds, 2 * π)

    # # Define the rotation matrix
    # R = [cos(θ) sin(θ) 0.0; -sin(θ) cos(θ) 0.0; 0.0 0.0 1.0]

    # # Perform the transformation
    # r_ecef = R * r
    # # v_ecef = R * v

    return r_ecef
end