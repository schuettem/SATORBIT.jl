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

i = 96.0 # Inclination (degrees)
f = 40.0 # True Anomaly (degrees)
Ω = 106.0 # Right Ascension of the Ascending Node (degrees)
ω = 234.0 # Argument of Periapsis (degrees)

init_orbit = SATORBIT.COES(a, e, i, Ω, ω, f)

start_date = SATORBIT.DateTime(2020, 5, 10, 12, 0, 0)

J2 = false
aero = true
disturbances = SATORBIT.Pertubations(J2, aero)

orbit = SATORBIT.Orbit(satellite, central_body, init_orbit, start_date)

# Simulation Parameters
nbr_orbits = 2 # Number of orbits to simulate
nbr_steps = 200 # Number of total steps

SATORBIT.simulate_orbit!(orbit, disturbances, nbr_orbits, nbr_steps)

# SATORBIT.plot_3d(orbit)
# SATORBIT.plot_ground_track(orbit, "+proj=merc")
SATORBIT.plot_atmosphere(orbit)
# SATORBIT.plot_coes(orbit)
