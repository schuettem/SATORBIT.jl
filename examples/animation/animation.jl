using SATORBIT
using GLMakie
using GeometryBasics
using LinearAlgebra
using CSV
using DataFrames

GLMakie.activate!()

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

i = 0.0 # Inclination (degrees)
f = 40.0 # True Anomaly (degrees)
Ω = 106.0 # Right Ascension of the Ascending Node (degrees)
ω = 234.0 # Argument of Periapsis (degrees)

init_orbit = SATORBIT.COES(a, e, i, Ω, ω, f)
start_date = SATORBIT.DateTime(2020, 8, 29, 0, 0, 0)

J2 = false
aero = false
disturbances = SATORBIT.Pertubations(J2, aero)

# Simulation Parameters
nbr_orbits = 1 # Number of orbits to simulate
nbr_steps = 200 # Number of total steps

fig = Figure(size = (800, 800), backgroundcolor = :black)
ax = Axis3(fig[1, 1], width = 600, height = 600, aspect = (1, 1, 1))
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

# Add the Earth
earth_radius = 6371 * 1e3 # Earth's radius in meters
θ = range(0, 2π, length=100)
φ = range(0, π, length=50)
x_earth = [earth_radius * sin(φ) * cos(θ) for φ in φ, θ in θ]
y_earth = [earth_radius * sin(φ) * sin(θ) for φ in φ, θ in θ]
z_earth = [earth_radius * cos(φ) for φ in φ, θ in θ]

surface!(ax, x_earth, y_earth, z_earth, color = :lightblue, transparency = false)

is_running = Observable(false)

button_size = (100, 30)
button_box = GridLayout(fig[1, 2])

start_button = Button(fig, label = "Start", width=button_size[1], height=button_size[2])
stop_button = Button(fig, label = "Stop", width=button_size[1], height=button_size[2])
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

# load coastlines from csv (lat, lon)
coastline_africa = CSV.read("./examples/animation/coastlines/coastlines_africa_3d.csv", DataFrame, header = ["lon", "lat"])
# transform into ecef
coastline_africa_ecef = zeros(length(coastline_africa[:,1]), 3)
for i in 1:length(coastline_africa[:,1])
    lat = coastline_africa[i,2]
    lon = coastline_africa[i,1]
    r_coast = SATORBIT.geo2ecef(deg2rad(lat), deg2rad(lon), central_body.radius)
    coastline_africa_ecef[i,:] = r_coast
end

# transform into eci
coastline_africa_eci = zeros(length(coastline_africa[:,1]), 3)
for i in 1:length(coastline_africa[:,1])
    r_coast_eci = SATORBIT.ecef2eci(coastline_africa_ecef[i, :], start_date)
    coastline_africa_eci[i,1] = r_coast_eci[1]
    coastline_africa_eci[i,2] = r_coast_eci[2]
    coastline_africa_eci[i,3] = r_coast_eci[3]
end
coastline_africa_eci_x = Observable(coastline_africa_eci[:,1])
coastline_africa_eci_y = Observable(coastline_africa_eci[:,2])
coastline_africa_eci_z = Observable(coastline_africa_eci[:,3])
lines!(ax, coastline_africa_eci_x, coastline_africa_eci_y, coastline_africa_eci_z, color = :black)

# plot satellite
scatter!(ax, satellite_pos_x, satellite_pos_y, satellite_pos_z, markersize = 10, color = :red)

limits!(ax, -r_0_mag, r_0_mag, -r_0_mag, r_0_mag, -r_0_mag, r_0_mag)

# remove coordinate system
hidedecorations!(ax)

display(fig)

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

                for i in 1:length(coastline_africa[:,1])
                    r_coast_eci = SATORBIT.ecef2eci(coastline_africa_ecef[i, :], orbit.time_utc[end])
                    coastline_africa_eci[i,1] = r_coast_eci[1]
                    coastline_africa_eci[i,2] = r_coast_eci[2]
                    coastline_africa_eci[i,3] = r_coast_eci[3]
                end
                coastline_africa_eci_x[] = coastline_africa_eci[:,1]
                coastline_africa_eci_y[] = coastline_africa_eci[:,2]
                coastline_africa_eci_z[] = coastline_africa_eci[:,3]
            end
        end
        sleep(1/60)
    end
end

animation(orbit, disturbances, nbr_orbits, nbr_steps)
