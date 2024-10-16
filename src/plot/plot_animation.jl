# Create the animation
function create_animation(orbit::OrbitPropagation)
    fig = Figure(size = (800, 600))
    ax = Axis3(fig[1, 1], xlabel = "X", ylabel = "Y", zlabel = "Z")

    # Add the Earth
    earth_radius = 6371 * 1e3 # Earth's radius in meters
    θ = range(0, 2π, length=100)
    φ = range(0, π, length=50)
    x_earth = [earth_radius * sin(φ) * cos(θ) for φ in φ, θ in θ]
    y_earth = [earth_radius * sin(φ) * sin(θ) for φ in φ, θ in θ]
    z_earth = [earth_radius * cos(φ) for φ in φ, θ in θ]

    surface!(ax, x_earth, y_earth, z_earth, color = :lightblue, transparency = false)

    # Plot the orbit
    x = [eci.r[1] for eci in orbit.eci]
    y = [eci.r[2] for eci in orbit.eci]
    z = [eci.r[3] for eci in orbit.eci]
    lines!(ax, x, y, z, color = :blue)

    # Create the satellite marker
    satellite_marker = scatter!(ax, [Point3f0(x[1], y[1], z[1])], color = :red, markersize = 10)

    # Animation function
    function update_frame(frame)
        idx = frame % length(x) + 1
        satellite_marker[1] = Point3f0(x[idx], y[idx], z[idx])
    end

    # Create the animation
    record(fig, "orbit_animation.mp4", 1:length(x); framerate = 30) do frame
        update_frame(frame)
    end
end