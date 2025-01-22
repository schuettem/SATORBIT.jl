using SATORBIT

# Satellite Parameters
c_d = 2.2 # Drag Coefficient
area = 0.1 # Cross-sectional area (m^2)
mass = 1.0 # Mass (kg)

satellite = SATORBIT.Satellite(c_d, area, mass)

# Orbit Parameters
central_body = SATORBIT.Earth()

alt_perigee = 300e3
radius_perigee = central_body.radius + alt_perigee
alt_apogee = 300e3
radius_apogee = central_body.radius + alt_apogee

e = (radius_apogee - radius_perigee) / (radius_apogee + radius_perigee) # Eccentricity
a = (radius_perigee + radius_apogee) / 2.0 # Semi-major axis

i = 96.7 # Inclination (degrees)
f = 40.0 # True Anomaly (degrees)
Ω = 106.0 # Right Ascension of the Ascending Node (degrees)
ω = 234.0 # Argument of Periapsis (degrees)

init_orbit = SATORBIT.COES(a, e, i, Ω, ω, f)

# Simulation Parameters
nbr_orbits = 2 # Number of orbits to simulate
nbr_steps = 200 # Number of total steps
J2 = false
aero = false
disturbances = SATORBIT.Pertubations(J2, aero)

years = range(2000, 2024, step = 1)

temperatures = Float64[] # Temperature in K at each time step in all orbit
velocity = Float64[] # Relative velocity in m/s in the ECI frame to the atmosphere at each time step in all orbit

for year in years

    start_date = SATORBIT.DateTime(year, 5, 10, 12, 0, 0)
    orbit = SATORBIT.Orbit(satellite, central_body, init_orbit, start_date)

    SATORBIT.simulate_orbit!(orbit, disturbances, nbr_orbits, nbr_steps)

    atmosphere_orbit = SATORBIT.atmosphere_orbit_data(orbit) # List of atmosphere data at each time step in the orbit

    for (j, atmosphere) in enumerate(atmosphere_orbit)
        push!(temperatures, atmosphere.temperature)
        v_orbit = orbit.eci[j].v
        v_atm = atmosphere.velocity
        v_rel = SATORBIT.norm(v_orbit - v_atm)
        push!(velocity, v_rel)
    end
end

println("Mean temperature: ", SATORBIT.mean(temperatures))
println("Maximum temperature: ", SATORBIT.maximum(temperatures))
println("Minimum temperature: ", SATORBIT.minimum(temperatures))
println("Mean relative velocity: ", SATORBIT.mean(velocity))
