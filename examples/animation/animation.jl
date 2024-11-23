using SATORBIT
using FileIO
using GLMakie
using GeometryBasics
using LinearAlgebra
using Dates
using Printf
include("gui.jl")

GLMakie.activate!()

# Satellite Parameters
c_d = 2.2 # Drag Coefficient
area = 1.0 # Cross-sectional area (m^2)
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

i = 52.0 # Inclination (degrees)
f = 40.0 # True Anomaly (degrees)
Ω = 106.0 # Right Ascension of the Ascending Node (degrees)
ω = 234.0 # Argument of Periapsis (degrees)

init_orbit = SATORBIT.COES(a, e, i, Ω, ω, f)

start_date = SATORBIT.DateTime(2020, 5, 10, 12, 0, 0)

J2 = false
aero = true
disturbances = SATORBIT.Pertubations(J2, aero)

# inital eci position
r_0, _ = SATORBIT.coes2eci(init_orbit, central_body.μ)
r_0_mag = norm(r_0)

orbit = Observable(SATORBIT.Orbit(satellite, central_body, init_orbit, start_date))

# Observables:
satellite_pos_x = Observable(r_0[1])
satellite_pos_y = Observable(r_0[2])
satellite_pos_z = Observable(r_0[3])
date_label = Observable(Dates.format(start_date, "yyyy-mm-dd HH:MM:SS"))
altitude = round((r_0_mag - central_body.radius) / 1e3, digits=2)
altitude_label = Observable("")
altitude_label[] = @sprintf("Altitude: %.2f km", altitude)

# Fig:
fig, ax = create_gui()

is_running = Observable(false)

# plot the satellite
scatter!(ax, satellite_pos_x, satellite_pos_y, satellite_pos_z, markersize = 10, color = :red)

# Earth:
earth = plot_earth(ax)
rotate_earth(earth, start_date)

# plot ECI frame
plot_eci_frame(ax)

# plot ECEF frame
x_ecef, y_ecef, z_ecef = plot_ecef_frame(ax)
rotate_ecef_frame(x_ecef, y_ecef, z_ecef, start_date)

function animation(orbit, disturbances)
    while isopen(fig.scene)
        if is_running[]
            orbit_part = 1 / 200
            for i in 1:200
                if !is_running[]
                    break
                end

                SATORBIT.simulate_orbit!(orbit[], disturbances, orbit_part, 2)

                r = orbit[].eci[end].r

                satellite_pos_x[] = r[1]
                satellite_pos_y[] = r[2]
                satellite_pos_z[] = r[3]
                date_label[] = Dates.format(orbit[].time_utc[end], "yyyy-mm-dd HH:MM:SS")
                altitude = round((norm(r) - orbit[].central_body.radius) / 1e3 , digits=2)
                altitude_label[] = @sprintf("Altitude: %.2f km", altitude)

                if altitude < 100 # stop the simulation if the satellite is below 100 km
                    is_running[] = false
                    altitude_label[] = @sprintf("Altitude below 100 km Simulation stopped")
                end

                # Rotate the Earth
                rotate_earth(earth, orbit[].time_utc[end])
                rotate_ecef_frame(x_ecef, y_ecef, z_ecef, orbit[].time_utc[end])

                sleep(1/60) # for visibility of the animation (60 fps)
            end
        end
        sleep(1/60)
    end
end

display(fig)

animation(orbit, disturbances)
