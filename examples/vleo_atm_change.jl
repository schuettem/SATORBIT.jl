#=
    Get the mean temperature, maximum temperature, minimum temperature,
    mean relative velocity, and mean atmoic oxygen density
=#

using SATORBIT

# Satellite Parameters
c_d = 2.2 # Drag Coefficient
area = 0.1 # Cross-sectional area (m^2)
mass = 1.0 # Mass (kg)

satellite = SATORBIT.Satellite(c_d, area, mass)

# Orbit Parameters
central_body = SATORBIT.Earth()

alt_perigee = 270e3
radius_perigee = central_body.radius + alt_perigee
alt_apogee = 270e3
radius_apogee = central_body.radius + alt_apogee

e = (radius_apogee - radius_perigee) / (radius_apogee + radius_perigee) # Eccentricity
a = (radius_perigee + radius_apogee) / 2.0 # Semi-major axis

i = 90 # Inclination (degrees)
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
density_aox = Float64[] # O Density in kg/m^3 at each time step in all orbit
density_an = Float64[] # N Density in kg/m^3 at each time step in all orbit
density_n2 = Float64[] # N2 Density in kg/m^3 at each time step in all orbit
polar_angles = Float64[] # Polar angle in degrees at each time step in all orbit
total_mass_density = Float64[] # Total mass density in kg/m^3 at each time step in all orbit

for year in years

    start_date = SATORBIT.DateTime(year, 5, 10, 12, 0, 0)
    orbit = SATORBIT.Orbit(satellite, central_body, init_orbit, start_date)

    SATORBIT.simulate_orbit!(orbit, disturbances, nbr_orbits, nbr_steps)

    atmosphere_orbit = SATORBIT.atmosphere_orbit_data(orbit) # List of atmosphere data at each time step in the orbit

    for (j, atmosphere) in enumerate(atmosphere_orbit)
        push!(temperatures, atmosphere.temperature)
        n_aox = atmosphere.o_density
        push!(density_aox, n_aox)
        n_an = atmosphere.n_density
        push!(density_an, n_an)
        n_n2 = atmosphere.n2_density
        push!(density_n2, n_n2)

        n_total = atmosphere.total_mass_density
        push!(total_mass_density, n_total)
        v_orbit = orbit.eci[j].v
        v_atm = atmosphere.velocity
        v_rel = SATORBIT.norm(v_orbit - v_atm)
        push!(velocity, v_rel)

        v_orbit_tnw = SATORBIT.eci2tnw(orbit.eci[j].r, v_orbit, v_orbit)
        v_atm_tnw = SATORBIT.eci2tnw(orbit.eci[j].r, v_orbit, v_atm)
        v_tnw = v_orbit_tnw - v_atm_tnw
        theta = atand(v_tnw[3], v_tnw[1])
        push!(polar_angles, theta)
    end
end

println("Height of the satellite: ", alt_perigee/1000, " km")
println("---")
println("Mean atomic oxygen density: ", SATORBIT.mean(density_aox))
println("Maximum atomic oxygen density: ", SATORBIT.maximum(density_aox))
println("Minimum atomic oxygen density: ", SATORBIT.minimum(density_aox))
println("---")
println("Mean atomic nitrogen density: ", SATORBIT.mean(density_an))
println("Maximum atomic nitrogen density: ", SATORBIT.maximum(density_an))
println("Minimum atomic nitrogen density: ", SATORBIT.minimum(density_an))
println("---")
println("Mean molecular nitrogen density: ", SATORBIT.mean(density_n2))
println("Maximum molecular nitrogen density: ", SATORBIT.maximum(density_n2))
println("Minimum molecular nitrogen density: ", SATORBIT.minimum(density_n2))
println("---")
println("Mean total mass density: ", SATORBIT.mean(total_mass_density))
println("Maximum total mass density: ", SATORBIT.maximum(total_mass_density))
println("Minimum total mass density: ", SATORBIT.minimum(total_mass_density))
println("---")
println("Mean polar angle: ", SATORBIT.mean(polar_angles))
println("Maximum polar angle: ", SATORBIT.maximum(polar_angles))
println("Minimum polar angle: ", SATORBIT.minimum(polar_angles))
println("---")
println("Mean temperature: ", SATORBIT.mean(temperatures))
println("Maximum temperature: ", SATORBIT.maximum(temperatures))
println("Minimum temperature: ", SATORBIT.minimum(temperatures))
println("---")
println("Mean relative velocity: ", SATORBIT.mean(velocity))
