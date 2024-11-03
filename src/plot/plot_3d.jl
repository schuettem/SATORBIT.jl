function plot_3d(orbit::Orbit)
    GLMakie.activate!()

    fig = Figure()
    x = Float64[]
    y = Float64[]
    z = Float64[]

    for eci in orbit.eci
        push!(x, eci.r[1])
        push!(y, eci.r[2])
        push!(z, eci.r[3])
    end

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
    lines!(ax, x, y, z, color = :blue)
    scatter!(ax, x[1], y[1], z[1], color = :red)
    scatter!(ax, x[end], y[end], z[end], color = :green)

    return fig
end