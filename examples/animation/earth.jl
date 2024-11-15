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

orbit = SATORBIT.Orbit(satellite, central_body, init_orbit, start_date)

r = orbit.eci[1].r

figure = Figure(backgroundcolor = :black)
ax = Axis3(figure[1, 1], aspect = (1, 1, 1), yreversed = true, xreversed = true)
hidedecorations!(ax)

scatter!(ax, r[1], r[2], r[3], color = :red)

earth_radius = 6371 * 1e3
data = load(Makie.assetpath("earth.png"))

# Get the transformation matrix from ECI to ECEF
et = SATORBIT.utc2et(start_date)
R_eci_ecef = SATORBIT.pxform("J2000", "ITRF93", et)

color = Sampler(data)

sphere = Sphere(Point3f0(0, 0, 0), earth_radius)
earth_mesh = mesh!(ax, sphere, color = color, transparency = false)

# Calculate rotation angle (Greenwich Sidereal Time)
theta = atan(R_eci_ecef[1, 1], R_eci_ecef[2, 1]) + π / 2
theta_deg = rad2deg(theta)
println("Greenwich Sidereal Time: $theta_deg")

# Rotate the Earth mesh
GLMakie.rotate!(earth_mesh, Vec3f0(0, 0, 1), theta)

# plot eci frame axes as arrows
x_eci = (earth_radius  + 1e6) * [1, 0, 0]
y_eci = (earth_radius  + 1e6) * [0, 1, 0]
z_eci = (earth_radius  + 1e6) * [0, 0, 1]

x_eci = (earth_radius + 1e6) * Vec3f0(1, 0, 0)
y_eci = (earth_radius + 1e6) * Vec3f0(0, 1, 0)
z_eci = (earth_radius + 1e6) * Vec3f0(0, 0, 1)

arrows!(ax, [Point3f0(0, 0, 0)], [Point3f0(x_eci...)], arrowsize = 1e6, color = :red)
arrows!(ax, [Point3f0(0, 0, 0)], [Point3f0(y_eci...)], arrowsize = 1e6, color = :green)
arrows!(ax, [Point3f0(0, 0, 0)], [Point3f0(z_eci...)], arrowsize = 1e6, color = :blue)

# plot ecef frame axes as arrows
R_ecef_eci = inv(R_eci_ecef)
x_ecef = R_ecef_eci * x_eci
y_ecef = R_ecef_eci * y_eci
z_ecef = R_ecef_eci * z_eci

x_ecef = Vec3f0(x_ecef...)
y_ecef = Vec3f0(y_ecef...)
z_ecef = Vec3f0(z_ecef...)

arrows!(ax, [Point3f0(0, 0, 0)], [Point3f0(x_ecef...)], arrowsize = 1e6, color = :red)
arrows!(ax, [Point3f0(0, 0, 0)], [Point3f0(y_ecef...)], arrowsize = 1e6, color = :green)
arrows!(ax, [Point3f0(0, 0, 0)], [Point3f0(z_ecef...)], arrowsize = 1e6, color = :blue)

display(figure)
