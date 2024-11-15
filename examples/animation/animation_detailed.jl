using SATORBIT
using FileIO
using GLMakie
using GeometryBasics
using LinearAlgebra

GLMakie.activate!()

# Satellite Parameters
c_d = 2.2 # Drag Coefficient
area = 0.1 # Cross-sectional area (m^2)
mass = 1.0 # Mass (kg)

satellite = SATORBIT.Satellite(c_d, area, mass)

# Orbit Parameters
central_body = SATORBIT.Earth()

alt_perigee = 409e3
radius_perigee = central_body.radius + alt_perigee
alt_apogee = 409e3
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
aero = false
disturbances = SATORBIT.Pertubations(J2, aero)

# Simulation Parameters
nbr_orbits = 1 # Number of orbits to simulate
nbr_steps = 200 # Number of total steps

# inital eci position
r_0, _ = SATORBIT.coes2eci(init_orbit, central_body.μ)
r_0_mag = norm(r_0)

orbit = SATORBIT.Orbit(satellite, central_body, init_orbit, start_date)

satellite_pos_x = Observable(r_0[1])
satellite_pos_y = Observable(r_0[2])
satellite_pos_z = Observable(r_0[3])
satellite_track_x = Observable([r_0[1]])
satellite_track_y = Observable([r_0[2]])
satellite_track_z = Observable([r_0[3]])

# Figure:
figure = Figure(size = (800, 800), backgroundcolor = :black)
ax = Axis3(figure[1, 1], width = 600, height = 600, aspect = (1, 1, 1), yreversed = true, xreversed = true)
hidedecorations!(ax)

# Buttons
is_running = Observable(false)
button_size = (100, 30)
button_box = GridLayout(figure[1, 2])

start_button = Button(figure, label = "Start", width=button_size[1], height=button_size[2])
stop_button = Button(figure, label = "Stop", width=button_size[1], height=button_size[2])
button_box[1, 1] = start_button
button_box[2, 1] = stop_button

function start_simulation()
    is_running[] = true
end

function stop_simulation()
    is_running[] = false
end

on(start_button.clicks) do _
    println("Start simulation")
    start_simulation()
end

on(stop_button.clicks) do _
    println("Stop simulation")
    stop_simulation()
end

# plot the satellite
scatter!(ax, satellite_pos_x, satellite_pos_y, satellite_pos_z, markersize = 10, color = :red)

# Earth:
earth_radius = 6371 * 1e3
data = load(Makie.assetpath("earth.png"))
color = Sampler(data)

# Get the transformation matrix from ECI to ECEF
et = SATORBIT.utc2et(start_date)
R_eci_ecef = SATORBIT.pxform("J2000", "ITRF93", et)

sphere = Sphere(Point3f0(0, 0, 0), earth_radius)
earth_mesh = mesh!(ax, sphere, color = color, transparency = false)

# Calculate rotation angle (Greenwich Sidereal Time)
theta = atan(R_eci_ecef[1, 1], R_eci_ecef[2, 1]) + π/2

# Rotate the Earth mesh
GLMakie.rotate!(earth_mesh, Vec3f0(0, 0, 1), theta)

display(figure)

function animation(orbit::SATORBIT.Orbit, disturbances, nbr_orbits, nbr_steps)

    @async while true
        if is_running[]
            orbit_part = nbr_orbits / nbr_steps
            for i in 1:nbr_steps
                if !is_running[]
                    break
                end

                SATORBIT.simulate_orbit!(orbit, disturbances, orbit_part, 2)

                r = orbit.eci[end].r

                sleep(1/60) # for visability of the animation (60 fps)

                satellite_pos_x[] = r[1]
                satellite_pos_y[] = r[2]
                satellite_pos_z[] = r[3]

                push!(satellite_track_x[], r[1])
                push!(satellite_track_y[], r[2])
                push!(satellite_track_z[], r[3])
                lines!(ax, satellite_track_x, satellite_track_y, satellite_track_z, color = :blue)

                # Get the transformation matrix from ECI to ECEF
                et = SATORBIT.utc2et(orbit.time_utc[end])
                R_eci_ecef = SATORBIT.pxform("J2000", "ITRF93", et)

                theta = atan(R_eci_ecef[1, 1], R_eci_ecef[2, 1]) + π/2

                # Rotate the Earth mesh
                GLMakie.rotate!(earth_mesh, Vec3f0(0, 0, 1), theta)
            end
        end
        sleep(1/60)
    end
end

animation(orbit, disturbances, nbr_orbits, nbr_steps)