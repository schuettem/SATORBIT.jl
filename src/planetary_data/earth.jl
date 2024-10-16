abstract type Planet end

struct Earth <: Planet
    mass :: Float64 # kg
    radius :: Float64 # m
    μ :: Float64 # m^3 s^-2
    J2 :: Float64 # J2 pertubation coefficient
    atm_rot_vec :: Vector{Float64} # rad/s
    coastlines_file :: String

    function Earth()
        new(5.972e24, 6371e3, GRAVITY_CONSTANT * 5.972e24, 1.08262668e-3, [0.0, 0.0, 7.2921150e-5], "planetary_data/coastlines_earth.csv")
    end
end